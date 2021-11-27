defmodule Traffic.Network.JunctionServer do
  use GenServer
  use TypedStruct
  alias Traffic.Network.RoadServer
  alias Traffic.Network.Junction
  alias Traffic.Network.Timing.Strategy

  typedstruct module: State, enforce: true do
    field(:id, :any)
    field(:config, Traffic.Network.Config.t())
    field(:x, integer())
    field(:y, integer())
    field(:vehicles, list(), default: [])
    field(:paused, boolean(), default: false)
    field :timings, %{{pid(), atom()} => Timing.t()}, default: %{}
  end

  # Client
  def start_link(_, opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts,
      name: Traffic.via_tuple(__MODULE__, {Keyword.get(opts, :name), Keyword.get(opts, :id)})
    )
  end

  @impl true
  def init(opts) do
    Process.send_after(self(), :tick, 100)

    {:ok,
     %State{
       id: Keyword.get(opts, :id),
       config: Keyword.get(opts, :config),
       x: Keyword.get(opts, :x),
       y: Keyword.get(opts, :y)
     }}
  end

  def get_location(server) do
    GenServer.call(server, :get_location)
  end

  def get_distance(junction1, junction2) do
    Traffic.Geometry.distance(
      get_location(junction1),
      get_location(junction2)
    )
  end

  def add_linked_road(server, {side, road}) do
    GenServer.cast(server, {:add_linked_road, {side, road}})
  end

  def receive_vehicle(server, vehicle) do
    GenServer.cast(server, {:receive_vehicle, vehicle})
  end

  # Server (callbacks)

  @impl true
  def handle_call(:get_location, _from, %State{} = state) do
    {:reply, {state.x, state.y}, state}
  end

  @impl true
  def handle_cast({:receive_vehicle, vehicle}, %State{vehicles: vehicles} = state) do
    {:noreply, %{state | vehicles: [vehicle | vehicles]}}
  end

  @impl true
  def handle_cast(:pause, %State{} = state) do
    Process.send_after(self(), :tick, 10)

    {:noreply, %{state | paused: not state.paused}}
  end

  @impl true
  def handle_cast({:add_linked_road, {side, road_pid}}, %State{} = state) do
    new_timings =
      state.timings
      |> add_timing({road_pid, side}, state.config.timing_strategy)

    {:noreply, %{state | timings: new_timings}}
  end

  @impl true
  def handle_info(:tick, %State{} = state) do
    if not state.paused do
      Process.send_after(self(), :tick, 10)
    end

    timings =
      state.timings
      |> state.config.timing_strategy.tick()
      |> tap(fn timings ->
        timings
        |> Enum.each(fn {k, _} ->
          {road, side} = k

          if Strategy.get_color(state.timings, k) != Strategy.get_color(timings, k) do
            RoadServer.set_light(road, {side, Strategy.get_color(timings, k)})
          end
        end)
      end)

    # Push vehicles out, assume 0 time
    state.vehicles
    |> Enum.each(fn data ->
      {target, side, lane_no} = data.future_road
      RoadServer.receive_vehicle(target, invert(side), lane_no, data.vehicle)
    end)

    {
      :noreply,
      %{
        state
        | timings: timings,
          vehicles: []
      }
    }
  end

  def invert(:right), do: :left
  def invert(:left), do: :right

  defp add_timing(timings, {road, side}, strategy) do
    timings
    |> strategy.add_road({road, side})
  end
end
