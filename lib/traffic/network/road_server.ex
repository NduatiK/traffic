defmodule Traffic.Network.RoadServer do
  use GenServer
  use TypedStruct
  alias Traffic.Network.Road
  alias Traffic.Network.JunctionServer
  alias Traffic.Vehicles.VehicleServer
  alias Traffic.Network.Manager
  import Traffic.Network.Road, only: [invert: 1]

  typedstruct module: Junction, enforce: true do
    field(:junction, pid())
    field(:color, atom())
    field(:linked_roads, list())
  end

  typedstruct module: State, enforce: true do
    field(:id, integer())
    field(:road, Road.t())
    field(:junction_and_colors, %{atom() => Junction.t()})
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
    Process.send_after(self(), :broadcast, 1000)

    preload(Keyword.get(opts, :name), Keyword.get(opts, :id))
    from = Keyword.get(opts, :junction1)
    to = Keyword.get(opts, :junction2)
    length = JunctionServer.get_distance(from, to)

    road =
      Road.new(
        :"road_#{Keyword.get(opts, :name)}_#{Keyword.get(opts, :id)}",
        length
      )

    {:ok,
     %State{
       id: Keyword.get(opts, :id),
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

  def whats_ahead?(server, lane, position, distance \\ 40) do
    GenServer.call(server, {:whats_ahead?, lane, position, distance})
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

  def add_linked_road({server, _}, {side, road_side}, road) do
    GenServer.cast(server, {:add_linked_road, {side, road_side}, road})
  end

  def receive_vehicle(server, from_side, lane_no, vehicle) do
    GenServer.cast(server, {:receive_vehicle, from_side, lane_no, vehicle})
  end

  def vehicle_moved(server, vehicle, lane, new_position, new_speed) do
    GenServer.cast(server, {:vehicle_moved, vehicle, lane, new_position, new_speed})
  end

  def send_into_junction(server, vehicle, lane) do
    GenServer.cast(server, {:send_into_junction, vehicle, lane})
  end

  def pause(server) do
    # GenServer.cast(server, :pause)
  end

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
  def handle_call(
        {:whats_ahead?, lane, position, distance},
        _from,
        %State{} = state
      ) do
    visual_info =
      []
      |> maybe_add_junction_info(state, position, lane, distance)
      |> maybe_add_vehicle_info(state, position, lane, distance)

    {:reply, visual_info, state}
  end

  @impl true
  def handle_cast(:pause, %State{} = state) do
    {:noreply, state}
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
  def handle_cast({:add_linked_road, {my_side, road_side}, {road, arterial}}, %State{} = state) do
    junction_and_colors =
      state.junction_and_colors
      |> Map.update!(my_side, fn map ->
        map
        |> Map.update!(:linked_roads, fn roads ->
          [{road, arterial, road_side} | roads]
        end)
      end)

    {:noreply, %{state | junction_and_colors: junction_and_colors}}
  end

  @impl true
  def handle_cast({:send_into_junction, vehicle, lane}, %State{} = state) do
    {road, _} = Road.remove_vehicle(state.road, vehicle, lane)

    {target, _arterial, side} = select_road(state, lane)

    vehicle_data = %{future_road: {target, side, 0}, vehicle: vehicle}

    JunctionServer.receive_vehicle(state.junction_and_colors[lane].junction, vehicle_data)

    {:noreply, %{state | road: road}}
  end

  @impl true
  def handle_cast({:vehicle_moved, vehicle, lane, new_position, new_speed}, %State{} = state) do
    road = Road.update_position_and_speed(state.road, vehicle, lane, new_position, new_speed)

    Phoenix.PubSub.broadcast(Traffic.PubSub, "road_#{inspect(self())}", {
      __MODULE__,
      %{pid: self()}
    })

    {:noreply, %{state | road: road}}
  end

  @impl true
  def handle_cast({:receive_vehicle, side, lane_no, vehicle}, %State{} = state) do
    lane_count = Enum.count(Map.from_struct(state.road)[side])

    vehicles = %{lane_no => [%{vehicle: vehicle, speed: 0}]}

    VehicleServer.send_road_details(vehicle,
      road: self(),
      position: 0,
      lane: side,
      road_length: state.road.length
    )

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

    {:noreply, %{state | road: road}}
  end

  # @impl true
  # def handle_info(:broadcast, state) do
  #   Process.send_after(self(), :broadcast, 100)

  #   Phoenix.PubSub.broadcast(Traffic.PubSub, "road_#{inspect(self())}", {
  #     __MODULE__,
  #     %{pid: self()}
  #   })

  #   {:noreply, state}
  # end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp get_lights(state) do
    state.junction_and_colors
    |> Enum.map(fn {side, data} ->
      {side, data.color}
    end)
    |> Enum.into(%{})
  end

  defp maybe_add_junction_info(visual_info, state, position, lane, distance) do
    if state.road.length - position > distance do
      visual_info
    else
      color =
        state.junction_and_colors
        |> Map.get(lane)
        |> Map.get(:color)

      [{:junction, state.road.length - position, color} | visual_info]
    end
  end

  defp maybe_add_vehicle_info(visual_info, state, position, lane, distance) do
    case Road.vehicles_ahead_of(state.road, position, lane, distance) do
      [] ->
        visual_info

      [lead] ->
        {speed, lead_position, _pid} = lead
        [{:lead_vehicle, speed, lead_position - position} | visual_info]

      [lead | other] ->
        {speed, lead_position, _pid} = lead

        ave_speed =
          other
          |> Enum.map(fn {speed, _, _} -> speed end)
          |> Enum.sum()
          |> Kernel./(Enum.count(other))

        [
          {:lead_vehicle, speed, lead_position - position},
          {:pack_vehicles, ave_speed}
          | visual_info
        ]
    end
  end

  defp preload(name, _id) do
    me = self()

    Task.async(fn ->
      :timer.sleep(1000)
      {:ok, pid} = Manager.start_vehicle(name)
      {:ok, pid1} = Manager.start_vehicle(name)
      # {:ok, pid2}=Manager.start_vehicle(name)
      # {:ok, pid3}=Manager.start_vehicle(name)

      receive_vehicle(me, :left, 0, pid)
      receive_vehicle(me, :right, 0, pid1)
    end)
  end

  def select_road(state, current_lane) do
    case state.junction_and_colors[current_lane].linked_roads do
      [] ->
        {_target = self(), _target_lane = invert(current_lane)}

      roads ->
        weighted_random(roads)
    end
  end

  defp weighted_arterial({_, arterial, _}) do
    if arterial, do: 10000, else: 1
  end

  defp weighted_random(roads) do
    distribution_range =
      roads
      |> Enum.map(&weighted_arterial/1)
      |> Enum.sum()

    random_number = :rand.uniform_real() * distribution_range

    roads
    |> Enum.map(&{&1, weighted_arterial(&1)})
    |> Enum.reduce_while(0, fn
      # stop when the the random number is between
      # the upper and lower bounds of the profile
      {generator, size}, lower_bound when random_number <= lower_bound + size ->
        {:halt, generator}

      # otherwise move to next profile
      {_, size}, lower_bound ->
        {:cont, lower_bound + size}
    end)
  end
end
