defmodule Traffic.Network.RoadServer do
  use GenServer
  use TypedStruct
  alias Traffic.Network.Road
  alias Traffic.Network.JunctionServer

  typedstruct module: Junction, enforce: true do
    field(:junction, pid())
    field(:color, atom())
    field(:linked_roads, list())
  end

  typedstruct module: State, enforce: true do
    # field(:id, :any)
    field(:road, Road.t())
    field(:junction_and_colors, %{atom() => Junction.t()})

    field(:paused, boolean(), default: false)
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
    Process.send_after(self(), :tick, :rand.uniform(500))

    from = Keyword.get(opts, :junction1)
    to = Keyword.get(opts, :junction2)

    road = Road.preloaded(:"road_#{Keyword.get(opts, :name)}_#{Keyword.get(opts, :id)}")

    TrafficWeb.Endpoint.subscribe("junction_#{inspect(from)}")
    TrafficWeb.Endpoint.subscribe("junction_#{inspect(to)}")

    {:ok,
     %State{
       junction_and_colors: %{
         left: %Junction{junction: from, color: :red, linked_roads: []},
         right: %Junction{junction: to, color: :red, linked_roads: []}
       },
       road: road
     }}
  end

  def get_road(server) do
    GenServer.call(server, :get_road)
  end

  def get_light(server) do
    GenServer.call(server, :get_light)
  end

  def set_light(server, {side, color}) do
    GenServer.cast(server, {:set_light, side, color})
  end

  def get_road_and_lights(server) do
    GenServer.call(server, :get_road_and_lights)
  end

  def add_linked_road(server, {side, road_side}, road) do
    GenServer.cast(server, {:add_linked_road, {side, road_side}, road})
  end

  def receive_vehicle(server, side, lane_no, vehicle) do
    GenServer.cast(server, {:receive_vehicle, side, lane_no, vehicle})
  end

  def pause(server) do
    GenServer.cast(server, :pause)
  end

  # @impl true
  # def handle_call(:get_graph, _from, %{graph: network} = state) do
  #   {:reply, network, state}
  # end

  @impl true
  def handle_call(:get_road, _from, %{road: road} = state) do
    {:reply, road, state}
  end

  @impl true
  def handle_call(:get_light, _from, state) do
    lights = get_lights(state)
    {:reply, lights, state}
  end

  @impl true
  def handle_call(:get_road_and_lights, _from, %{road: road} = state) do
    lights = get_lights(state)
    {:reply, {road, lights}, state}
  end

  @impl true
  def handle_cast(:pause, %State{} = state) do
    if state.paused do
      Process.send_after(self(), :tick, 10)
    end

    {:noreply, %{state | paused: not state.paused}}
  end

  @impl true
  def handle_cast({:set_light, side, color}, %State{} = state) do
    junction_and_colors =
      state.junction_and_colors
      |> Map.update!(side, fn data ->
        %{data | color: color}
      end)

    Phoenix.PubSub.broadcast(Traffic.PubSub, "road_#{inspect(self())}", {
      __MODULE__,
      %{pid: self()}
    })

    {:noreply,
     %{
       state
       | junction_and_colors: junction_and_colors
     }}
  end

  @impl true
  def handle_cast({:add_linked_road, {my_side, road_side}, road}, %State{} = state) do
    junction_and_colors =
      state.junction_and_colors
      |> Map.update!(my_side, fn map ->
        map
        |> Map.update!(:linked_roads, fn roads ->
          [{road, road_side} | roads]
        end)
      end)

    {:noreply, %{state | junction_and_colors: junction_and_colors}}
  end

  @impl true
  def handle_cast({:receive_vehicle, side, lane_no, vehicle}, state) do
    # future_road: {#PID<0.703.0>, :left, 0},
    # vehicle: %Traffic.Vehicles.Vehicle{

    lane_count = Enum.count(Map.from_struct(state.road)[side])

    vehicles = %{lane_no => [vehicle]}

    road =
      Road.join_road(
        state.road,
        side,
        0..(lane_count - 1)
        |> Enum.reduce(vehicles, fn lane_no, lanes ->
          Map.put_new(lanes, lane_no, [])
        end)
        |> Enum.to_list()
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(&elem(&1, 1))
      )

    road
    |> Map.from_struct()

    # |> IO.inspect()

    {:noreply, %{state | road: road}}
  end

  @impl true
  def handle_info(:tick, %State{} = state) do
    if not state.paused do
      Process.send_after(self(), :tick, 10)
    end

    # IO.inspect(state.road.name)
    # IO.inspect(state.junction_and_colors)

    %{left: into_left, right: _, road: road} =
      state.road
      |> Road.step(
        :left,
        [{:left, state.junction_and_colors.left.color}],
        state.junction_and_colors.left.linked_roads
      )

    into_left = Enum.flat_map(into_left, & &1)

    if not Enum.empty?(into_left) do
      into_left
      |> Enum.each(fn vehicle ->
        JunctionServer.receive_vehicle(state.junction_and_colors.left.junction, vehicle)
      end)
    end

    %{left: _, right: into_right2, road: road} =
      road
      |> Road.step(
        :right,
        [{:right, state.junction_and_colors.right.color}],
        state.junction_and_colors.right.linked_roads
      )

    into_right2 = Enum.flat_map(into_right2, & &1)

    if not Enum.empty?(into_right2) do
      into_right2
      |> Enum.each(fn vehicle ->
        JunctionServer.receive_vehicle(state.junction_and_colors.right.junction, vehicle)
      end)
    end

    Phoenix.PubSub.broadcast(Traffic.PubSub, "road_#{inspect(self())}", {
      __MODULE__,
      %{pid: self()}
    })

    {:noreply,
     %{
       state
       | road: road
     }}
  end

  defp get_lights(state) do
    state.junction_and_colors
    |> Enum.map(fn {side, data} ->
      {side, data.color}
    end)
    |> Enum.into(%{})
  end
end
