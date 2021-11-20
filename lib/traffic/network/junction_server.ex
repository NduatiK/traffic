defmodule Traffic.Network.JunctionServer do
  use GenServer
  use TypedStruct
  alias Traffic.Network.RoadServer
  alias Traffic.Network.Junction

  typedstruct module: State, enforced: true do
    field(:id, :any)
    field(:config, Traffic.Network.Config.t())
    field(:color, String.t())
    field(:x, integer())
    field(:y, integer())
    field(:vehicles, list(), default: [])
    field(:paused, boolean(), default: false)
    field :last_switch, integer()
  end

  # Client
  def start_link(_, opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts,
      name: Traffic.via_tuple(__MODULE__, {Keyword.get(opts, :name), Keyword.get(opts, :id)})
    )
  end

  # Server (callbacks)
  @impl true
  def init(opts) do
    Process.send_after(self(), :tick, :rand.uniform(5000))

    {:ok,
     %State{
       id: Keyword.get(opts, :id),
       config: Keyword.get(opts, :config),
       color: :red,
       x: Keyword.get(opts, :x),
       y: Keyword.get(opts, :y)
     }}
  end

  def get_location(server) do
    GenServer.call(server, :get_location)
  end

  def receive_vehicle(server, vehicle) do
    GenServer.cast(server, {:receive_vehicle, vehicle})
  end

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
  def handle_info(:tick, %State{} = state) do
    if not state.paused do
      Process.send_after(self(), :tick, 5000)
    end

    # Junction.update_lights(road, timings, config.junction_strategy)

    color = if(state.color == :red, do: :green, else: :red)

    Phoenix.PubSub.broadcast(Traffic.PubSub, "junction_#{inspect(self())}", {
      __MODULE__,
      %{pid: self(), color: color}
    })

    # TODO: Push vehicles out, assume 0 time
    state.vehicles
    |> Enum.each(fn data ->
      {target, side, lane_no} = data.future_road
      RoadServer.receive_vehicle(target, side, lane_no, data.vehicle)
    end)

    {
      :noreply,
      %{
        state
        | color: color,
          vehicles: []
      }
    }
  end
end
