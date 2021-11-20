defmodule Traffic.Network.RoadServer do
  use GenServer
  use TypedStruct
  alias Traffic.Network.Road
  alias Traffic.Network.JunctionServer

  typedstruct module: State, enforced: true do
    # field(:id, :any)
    field(:road, Road.t())
    field(:junction_and_colors, map())

    field(:paused, boolean(), default: false)
    field(:counter, integer(), default: 0)
    # field(:x, integer())
    # field(:y, integer())
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
         left: %{junction: from, color: :red, linked_roads: []},
         right: %{junction: to, color: :red, linked_roads: []}
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
        side
        |> IO.inspect(),
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

  def invert(:right), do: :left
  def invert(:left), do: :right

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
        :right,
        [{:left, state.junction_and_colors.left.color}],
        state.junction_and_colors.right.linked_roads
      )

    into_left = Enum.flat_map(into_left, & &1)

    if not Enum.empty?(into_left) do
      into_left
      |> Enum.each(fn vehicle ->
        JunctionServer.receive_vehicle(state.junction_and_colors.right.junction, vehicle)
      end)
    end

    %{left: _, right: into_right2, road: road} =
      road
      |> Road.step(
        :left,
        [{:right, state.junction_and_colors.right.color}],
        state.junction_and_colors.left.linked_roads
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
      %{pid: self(), counter: state.counter}
    })

    {:noreply,
     %{
       state
       | road: road,
         counter: state.counter + 1
     }}
  end

  @impl true
  def handle_info({Traffic.Network.JunctionServer, update}, state) do
    Phoenix.PubSub.broadcast(Traffic.PubSub, "road_#{inspect(self())}", {
      __MODULE__,
      %{pid: self(), counter: state.counter + 1}
    })

    junction_and_colors =
      state.junction_and_colors
      |> Enum.map(fn {side, data} ->
        if data.junction == update.pid do
          data = %{data | color: update.color}

          {side, data}
        else
          {side, data}
        end
      end)
      |> Enum.into(%{})

    {:noreply,
     %{
       state
       | junction_and_colors: junction_and_colors,
         counter: state.counter + 1
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
