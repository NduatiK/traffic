defmodule Traffic.Vehicles.VehicleServer do
  use GenServer
  alias Traffic.Vehicles.DriverProfile
  alias Traffic.Network.RoadServer
  use TypedStruct

  @tick_after round(1000 / 24)
  @look_ahead_after round(@tick_after / 4)

  typedstruct module: Vision do
    field(:junction_light, atom(), default: nil)
    field(:junction_distance, integer(), default: nil)
    field(:appx_distance_to_lead, integer(), default: nil)
    field(:appx_speed_of_lead, integer(), default: nil)
    field(:appx_speed_of_pack, integer(), default: nil)
  end

  typedstruct module: Position, enforce: true do
    @typedoc """
    What is the vehicle inside?
    - Is it a road?
    - Is it a junction with a target road?
    """
    @type container() :: {:road, atom()} | {:junction, {pid(), atom()}}

    field(:container, container())
    field(:pid, pid())
    field(:length, pid())
    field(:position, pid())
  end

  typedstruct module: State do
    @typedoc ""

    field(:visual_knowledge, Vision.t(), default: nil)
    field(:position, Position.t(), default: nil)
    field(:current_speed, integer(), default: 0)
    field(:current_acceleration, integer(), default: 0)
    field(:driver_profile, DriverProfile.t())

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
    Process.send_after(self(), :look_ahead, @look_ahead_after + 100)
    Process.send_after(self(), :tick, @tick_after)

    config = Keyword.get(opts, :config)

    %State{
      driver_profile: DriverProfile.random(config)
    }
    |> then(&{:ok, &1})
  end

  def send_road_details(vehicle, opts) do
    GenServer.cast(vehicle, {:send_road_details, opts})
  end

  def pause(server) do
    GenServer.cast(server, :pause)
  end

  def start_moving() do
  end

  def slow_down(_vehicle) do
  end

  def avoid_collision(vehicle, comparative_speed) do
    if comparative_speed == :lt do
      slow_down(vehicle)
    end
  end

  def join_junction(_junction_pid, _exit_road) do
  end

  # def change_lane() do
  # end

  # def enter_junction(server, pid, junction_length, position \\ 0) do
  #   enter_container(server, :junction, position, junction_length)
  # end

  # def enter_road(server, pid, road_length, position \\ 0) do
  #   enter_container(server, :road, position, road_length)
  # end

  # def enter_container(server, container_type, position, road_length) do
  #   GenServer.call(server, {:enter_container, container_type, position, road_length})
  # end

  @impl true
  def handle_cast(:pause, %State{} = state) do
    if state.paused do
      Process.send_after(self(), :tick, 10)
    end

    {:noreply, %{state | paused: not state.paused}}
  end

  @impl true
  def handle_cast({:send_road_details, opts}, %State{} = state) do
    road = Keyword.get(opts, :road)
    position = Keyword.get(opts, :position)
    lane = Keyword.get(opts, :lane)
    length = Keyword.get(opts, :road_length)

    {:noreply,
     %{
       state
       | position: %Position{
           container: {:road, lane},
           pid: road,
           length: length,
           position: position
         }
     }}
  end

  @impl true
  def handle_info(:look_ahead, %State{} = state) do
    Process.send_after(self(), :look_ahead, @look_ahead_after)

    vision =
      case state.position.container do
        {:road, lane} ->
          RoadServer.whats_ahead?(state.position.pid, lane, state.position.position)

        {:junction, {_target_road_pid, lane}} ->
          RoadServer.whats_ahead?(state.position.pid, lane, 0)
      end
      |> to_vision()

    {:noreply, %State{state | visual_knowledge: vision}}
  end

  @impl true
  def handle_info(:tick, %State{position: nil} = state) do
    Process.send_after(self(), :tick, 1000)
    IO.inspect("-")
    {:noreply, state}
  end

  def handle_info(:tick, %State{} = state) do
    Process.send_after(self(), :tick, @tick_after)

    # position_ = state.position.position + state.current_speed / 200
    position_ = state.position.position + state.current_speed / 20

    position_ = min(state.position.length, position_)

    current_speed =
      state.current_speed
      |> apply_jitter(state.driver_profile)

    # |> adjust_to_environment(state.visual_knowledge)

    position = %{
      state.position
      | position: position_
    }

    new_state = %State{
      state
      | current_speed: current_speed,
        position: position
    }

    {:noreply, update_parent(new_state)}
  end

  defp to_vision(items_ahead) do
    items_ahead
    |> Enum.reduce(%Vision{}, fn
      {:junction, distance, color}, vision ->
        vision
        |> Map.put(:junction_distance, distance)
        |> Map.put(:junction_light, color)

      {:lead_vehicle, speed, distance}, vision ->
        vision
        |> Map.put(:appx_distance_to_lead, distance)
        |> Map.put(:appx_speed_of_lead, speed)

      {:pack_vehicles, ave_speed}, vision ->
        vision
        |> Map.put(:appx_speed_of_pack, ave_speed)
    end)
  end

  def apply_jitter(current_speed, driver_profile) do
    delta = (DriverProfile.gauss(driver_profile) - current_speed) * 0.1
    current_speed + delta
  end

  def adjust_to_environment(current_speed, nil) do
    current_speed
  end

  def adjust_to_environment(
        current_speed,
        %Vision{junction_light: junction_light, appx_distance_to_lead: appx_distance_to_lead} =
          visual_knowledge
      ) do
    case {appx_distance_to_lead, junction_light} do
      {nil, nil} ->
        # No cars or junction ahead to worry about
        current_speed

      {nil, :green} ->
        # No cars ahead only worry about junction
        if current_speed > 20 do
          current_speed * 0.9
        else
          current_speed
        end

      {nil, _yellow_or_red} ->
        # No cars ahead only worry about junction
        current_speed * 0.5

      {lead, _} ->
        catching_up = visual_knowledge.appx_speed_of_lead < current_speed
        # No junction ahead only worry about cars
        cond do
          lead < 10 and catching_up ->
            visual_knowledge.appx_speed_of_lead * (10 - lead) / 10 +
              current_speed * lead / 10

          catching_up ->
            (visual_knowledge.appx_speed_of_lead + current_speed) / 2

          true ->
            current_speed
        end
    end
  end

  defp update_parent(%State{visual_knowledge: nil} = state) do
    IO.inspect("update_parent no knowledge")
    state
  end

  defp update_parent(%State{} = state) do
    case state.position.container do
      {:junction, _} ->
        state

      {:road, lane} ->
        if state.position.position == state.position.length and
             state.visual_knowledge.junction_light == :green do
          RoadServer.send_into_junction(state.position.pid, self(), lane)

          state
        else
          RoadServer.vehicle_moved(
            state.position.pid,
            self(),
            lane,
            state.position.position,
            state.current_speed
          )

          state
        end
    end
  end
end
