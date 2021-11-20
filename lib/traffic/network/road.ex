defmodule Traffic.Network.Road do
  @type road_end :: :left | :right
  @type name :: atom()

  use TypedStruct
  alias __MODULE__
  alias Traffic.Vehicles.Vehicle
  def scale, do: 4
  def vehicle_length, do: 0.35
  # def vehicle_length, do: 0.2

  typedstruct do
    field(:name, String.t(), enforce: true)

    # Location awareness
    field(:length, integer(), enforce: true)
    field(:right, list(list({pid(), float()})), default: [])
    field(:left, list({pid(), float()}), default: [])
  end

  def lanes(road) do
    {Enum.count(road.right), Enum.count(road.left)}
  end

  def scale_speed() do
    Application.get_env(:traffic, :scale_speed, 50)
  end

  def set_scale_speed(speed) do
    Application.put_env(:traffic, :scale_speed, speed)
  end

  def preloaded(name \\ :unique_road) do
    %Road{
      name: name,
      length: 10,
      right: [
        [
          {Vehicle.random(), 0},
          {Vehicle.random(), 3}
          # {Vehicle.random(), 5},
          # {Vehicle.random(), 6},
          # {Vehicle.random(), 9}
        ]
        # , [
        #   {Vehicle.random(), 0},
        #   {Vehicle.random(), 3},
        #   {Vehicle.random(), 5},
        #   {Vehicle.random(), 6},
        #   {Vehicle.random(), 9}
        # ]
      ],
      left: [
        # [
        #   {Vehicle.random(), 0.5},
        #   {Vehicle.random(), 1},
        #   {Vehicle.random(), 2},
        #   {Vehicle.random(), 4},
        #   {Vehicle.random(), 8},
        #   {Vehicle.random(), 9}
        # ],
        [
          {Vehicle.random(), 0}
          # {Vehicle.random(), 1},
          # {Vehicle.random(), 2},
          # {Vehicle.random(), 4},
          # {Vehicle.random(), 8},
          # {Vehicle.random(), 9}
        ]
      ]
    }
  end

  def preloaded(name, config) do
    driver_profiles = config.driver_profile_stats

    %Road{
      name: name,
      length: 10,
      right: [
        [
          # {Vehicle.random(driver_profiles), 0},
          # {Vehicle.random(driver_profiles), 3}
          # {Vehicle.random(driver_profiles), 5},
          # {Vehicle.random(driver_profiles), 6},
          # {Vehicle.random(driver_profiles), 9}
        ]
        # [
        #   {Vehicle.random(driver_profiles), 0},
        #   {Vehicle.random(driver_profiles), 3},
        #   {Vehicle.random(driver_profiles), 5},
        #   {Vehicle.random(driver_profiles), 6},
        #   {Vehicle.random(driver_profiles), 9}
        # ]
      ],
      left: [
        # [
        #   {Vehicle.random(driver_profiles), 0.5},
        #   {Vehicle.random(driver_profiles), 1},
        #   {Vehicle.random(driver_profiles), 2},
        #   {Vehicle.random(driver_profiles), 4},
        #   {Vehicle.random(driver_profiles), 8},
        #   {Vehicle.random(driver_profiles), 9}
        # ],
        [
          # {Vehicle.random(driver_profiles), 0},
          # {Vehicle.random(driver_profiles), 1},
          # {Vehicle.random(driver_profiles), 2},
          # {Vehicle.random(driver_profiles), 4},
          # {Vehicle.random(driver_profiles), 8},
          # {Vehicle.random(driver_profiles), 9}
        ]
      ]
    }
  end

  def step(road, lane, open_exits \\ [], road_names)

  def step(%{road: %Road{} = road}, lane, open_exits, road_names) do
    step(road, open_exits, road_names)
  end

  def step(%Road{} = road, lane, open_exits, road_names) do
    %{road: road, left: [], right: []}
    |> update_lanes(:left, lane, Enum.member?(open_exits, {:left, :green}), road_names)
    |> update_lanes(:right, lane, Enum.member?(open_exits, {:right, :green}), road_names)
  end

  def join_road(%Road{} = road, direction, nil) do
    road
  end

  def join_road(%Road{} = road, direction, vehicle_lanes) when is_list(vehicle_lanes) do
    # def join_road(%Road{} = road, direction, vehicle_lanes) do

    vehicle_join_road(
      road,
      direction,
      vehicle_lanes
      |> Enum.map(fn lane ->
        lane
        |> Enum.map(fn v -> {v, 0} end)
      end)
    )
  end

  @spec vehicle_join_road(Road.t(), Road.road_end(), [[{Vehicle.t(), float()}]]) :: Road.t()
  def vehicle_join_road(road = %{left: lanes}, :right, vehicles) do
    %{road | left: vehicle_join_lanes(lanes, vehicles)}
  end

  def vehicle_join_road(road = %{right: lanes}, :left, vehicles) do
    %{road | right: vehicle_join_lanes(lanes, vehicles)}
  end

  def vehicle_join_lanes(lanes, vehicles) do
    do_vehicle_join_lanes(lanes, vehicles)
  end

  def do_vehicle_join_lanes([], _) do
    []
  end

  def do_vehicle_join_lanes([lane1 | other_lanes], [vehicles | other_vehicles]) do
    [vehicles ++ lane1 | do_vehicle_join_lanes(other_lanes, other_vehicles)]
  end

  def to_exit(:left), do: :left
  def to_exit(:right), do: :right

  def update_lanes(data, lane_name, lane_to_step, _, _)
      when lane_name != lane_to_step do
    data
  end

  def update_lanes(%{road: road} = data, lane_name, _, can_exit, road_names) do
    {lanes, exits} =
      road
      |> Map.get(lane_name)
      |> Enum.with_index()
      |> Enum.map(fn {lane, index} ->
        lane
        |> Enum.reverse()
        |> Enum.flat_map_reduce({nil, []}, fn
          vehicle, {last_vehicle, exited_veh_acc} ->
            case move_forward(vehicle, last_vehicle, road, can_exit, road_names, index) do
              {[], _, future_road} ->
                {
                  [],
                  {
                    nil,
                    [%{vehicle: elem(vehicle, 0), future_road: future_road} | exited_veh_acc]
                  }
                }

              {vehicle = [{%{speed: speed}, _pos}], leader_position} ->
                {
                  vehicle,
                  {
                    {leader_position, speed},
                    exited_veh_acc
                  }
                }
            end
        end)
        |> then(fn {vehicles, {_, exited}} ->
          {Enum.reverse(vehicles), exited}
        end)
      end)
      |> Enum.unzip()

    %{data | road: Map.put(road, lane_name, lanes)}
    |> Map.put(to_exit(lane_name), exits)
  end

  defp move_forward({vehicle, location}, nil, road, can_exit, road_names, lane_index) do
    next_location = location + vehicle.speed / scale_speed()

    next_location =
      if can_exit,
        do: next_location,
        else: min(road.length - vehicle_length(), next_location)

    if next_location < road.length do
      {[{vehicle, next_location}], next_location}
    else
      future_road =
        road_names
        |> Enum.filter(fn {name, _} -> name != road.name end)
        |> Enum.random()
        |> then(fn {name, enter_direction} -> {name, enter_direction, lane_index} end)

      {[], next_location, future_road}
    end
  end

  @visibility_thresh 4
  defp move_forward(
         {vehicle, location},
         {leader_pos, leader_appx_speed},
         road,
         can_exit,
         road_names,
         lane_index
       ) do
    next_location =
      cond do
        leader_pos - location > @visibility_thresh ->
          location + vehicle.speed / scale_speed()

        true ->
          # No need to handle anything
          location + vehicle.speed / scale_speed()
      end

    next_location = min(leader_pos - vehicle_length(), next_location)

    next_location =
      if can_exit,
        do: next_location,
        else: min(road.length - vehicle_length(), next_location)

    if next_location < road.length do
      {[{vehicle, next_location}], next_location}
    else
      future_road =
        road_names
        |> Enum.filter(fn {name, _} -> name != road.name end)
        |> Enum.random()
        |> then(fn {name, enter_direction} -> {name, enter_direction, lane_index} end)

      {[], next_location, future_road}
    end
  end
end

defimpl Inspect, for: Traffic.Network.Road do
  @scale Traffic.Network.Road.scale()
  @vehicle_width Traffic.Network.Road.vehicle_length()

  def inspect(road, _opts) do
    "\nName: #{road.name}\n" <>
      String.duplicate("<", road.length * @scale) <>
      inspect_lanes(road.left, :down, road.length) <>
      String.duplicate("=", road.length * @scale) <>
      inspect_lanes(road.right, :up, road.length) <>
      String.duplicate(">", road.length * @scale)
  end

  @spec inspect_lanes(list(list({Vehicle.t(), float()})), :down | :up, non_neg_integer) ::
          nonempty_binary
  def inspect_lanes(lanes, direction, length) do
    Enum.map(lanes, &inspect_vehicles(direction, &1, length))
    |> Enum.intersperse("\n" <> String.duplicate("·", length * @scale))
    |> Enum.join()
    |> Kernel.<>("\n")
  end

  @spec inspect_vehicles(:down | :up, list({Vehicle.t(), float()}), non_neg_integer) ::
          nonempty_binary
  def inspect_vehicles(:down = direction, vehicles, length) do
    do_inspect_vehicles(direction, vehicles)
    |> String.trim_leading("\n")
    |> String.reverse()
    |> String.pad_leading(length * @scale)
    |> then(&("\n" <> &1))
  end

  def inspect_vehicles(:up = direction, vehicles, length) do
    do_inspect_vehicles(direction, vehicles)
    |> String.pad_trailing(length * @scale + 1)
  end

  @spec do_inspect_vehicles(:down | :up, list({Vehicle.t(), float()})) ::
          nonempty_binary
  def do_inspect_vehicles(direction, vehicles) do
    vehicles
    |> Enum.reduce({"\n", -@vehicle_width}, fn {vehicle, location}, {acc_str, prev_position} ->
      marker = vehicle.marker
      # marker = "◈"
      # marker = vehicle_art(direction)

      {
        acc_str <>
          String.duplicate(
            " ",
            round(max(0, (location - prev_position - @vehicle_width) * @scale))
          ) <>
          String.duplicate(marker, round(@vehicle_width * @scale)),
        # marker,
        location
      }
    end)
    |> elem(0)
  end

  def vehicle_art(:down) do
    # "◂"
    "«"
  end

  def vehicle_art(:up) do
    # "▸"
    "»"
  end
end
