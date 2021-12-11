defmodule Traffic.Vehicles.VehicleServer do
  use GenServer
  alias Traffic.Vehicles.DriverProfile
  alias Traffic.Network.RoadServer
  use TypedStruct

  @tick_after round(1000 / 24)
  @look_ahead_after round(@tick_after * 10)

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
    field(:waiting_time, integer(), default: 0)

    field(:id, integer(), enforce: true)
    field(:name, String.t(), enforce: true)

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
    Process.send_after(self(), :tick, @tick_after)

    config = Keyword.get(opts, :config)

    %State{
      driver_profile: DriverProfile.random(config),
      name: Keyword.get(opts, :name),
      id: Keyword.get(opts, :id)
    }
    |> then(&{:ok, &1})
  end

  def send_road_details(vehicle, opts) do
    GenServer.cast(vehicle, {:send_road_details, opts})
  end

  def pause(server) do
    GenServer.cast(server, :pause)
  end

  def get_vision(server) do
    GenServer.call(server, :get_vision)
  end
  @impl true
  def handle_call(:get_vision, _from,%State{} = state) do
    {:reply, state.visual_knowledge, state}
  end
  @impl true
  def handle_cast(:pause, %State{} = state) do
    if state.paused do
      Process.send_after(self(), :tick, 10)
    end

    {:noreply, %{state | paused: not state.paused}}
  end



  @impl true
  def handle_cast({:send_road_details, opts}, %State{} = state) do
    Process.send_after(self(), :look_ahead, @look_ahead_after)

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
    {:noreply, state}
  end

  def handle_info(:tick, %State{} = state) do
    if not state.paused do
      Process.send_after(self(), :tick, @tick_after)
    end

    position_ = state.position.position + state.current_speed / 3

    position_ = min(state.position.length, position_)

    current_speed =
      state.current_speed
      |> apply_jitter(state.driver_profile)
      |> adjust_to_environment(state.driver_profile, state.visual_knowledge)

    position = %{
      state.position
      | position: position_
    }

    new_state = %State{
      state
      | current_speed: current_speed,
        position: position
    }

    new_state
    |> update_parent()
    |> track_waiting()
    |> then(&{:noreply, &1})
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

  def adjust_to_environment(current_speed, _, nil) do
    current_speed
  end

  def adjust_to_environment(
        current_speed,
        driver_profile,
        %Vision{junction_light: junction_light, appx_distance_to_lead: appx_distance_to_lead} =
          visual_knowledge
      ) do
    case {appx_distance_to_lead, junction_light} do
      {nil, nil} ->
        # No cars or junction ahead to worry about
        current_speed * 0.95 +
          (0.05 + driver_profile.initial_acceleration / 50) * driver_profile.mean_speed

      {nil, :green} ->
        # No cars ahead only worry about junction
        if current_speed > 20 do
          current_speed * 0.9
        else
          current_speed
        end

      {nil, _yellow_or_red} ->
        # No cars ahead only worry about junction
        cond do
          visual_knowledge.junction_distance < 1 ->
            0

          visual_knowledge.junction_distance < 3 ->
            current_speed * 0.5

          true ->
            current_speed * 0.7
        end

      {lead, _} ->
        # Follow the cars
        catching_up = visual_knowledge.appx_speed_of_lead < current_speed
        leader_speed = visual_knowledge.appx_speed_of_lead

        cond do
          lead < 10 and leader_speed < 1 ->
            0

          (lead < 10 and leader_speed < 10) or (lead < 10 and catching_up) ->
            proportion_leader = :math.pow((10 - lead) / 10, 0.25)

            lead * proportion_leader +
              current_speed * (1 - proportion_leader)

          catching_up ->
            (visual_knowledge.appx_speed_of_lead + current_speed) / 2

          true ->
            current_speed
        end
    end
  end

  defp update_parent(%State{visual_knowledge: nil} = state) do
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

  def track_waiting(%State{current_speed: 0} = state) do
    %{state | waiting_time: state.waiting_time + 1}
  end

  def track_waiting(%State{current_speed: _, waiting_time: 0} = state) do
    state
  end

  def track_waiting(%State{current_speed: _, waiting_time: waiting_time} = state) do
    Traffic.Statistics.update_wait_time(state.name, state.id, waiting_time)
    %{state | waiting_time: 0}
  end
end
