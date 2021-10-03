defmodule Traffic.Network.Road do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Vehicles.Vehicle
  def scale, do: 4
  def vehicle_length, do: 0.25
  # def vehicle_length, do: 0.2

  typedstruct do
    field :name, String.t(), enforce: true

    # Location awareness
    field :length, integer(), enforce: true
    field :lanes_to_right, list(list({pid(), float()})), default: []
    field :lanes_to_left, list({pid(), float()}), default: []
  end

  def preloaded(name \\ :unique_road) do
    %Road{
      name: name,
      length: 10,
      lanes_to_right: [
        [
          {Vehicle.random(), 0},
          {Vehicle.random(), 3},
          {Vehicle.random(), 5},
          {Vehicle.random(), 6},
          {Vehicle.random(), 9}
        ]
      ],
      lanes_to_left: [
        # [
        #   {Vehicle.random(), 0.5},
        #   {Vehicle.random(), 1},
        #   {Vehicle.random(), 2},
        #   {Vehicle.random(), 4},
        #   {Vehicle.random(), 8},
        #   {Vehicle.random(), 9}
        # ],
        [
          {Vehicle.random(), 0},
          {Vehicle.random(), 1},
          {Vehicle.random(), 2},
          {Vehicle.random(), 4},
          {Vehicle.random(), 8},
          {Vehicle.random(), 9}
        ]
      ]
    }
  end

  def step(%{road: %Road{} = road}) do
    step(road)
  end

  def step(%Road{} = road, greens \\ []) do
    %{road: road, exited_to_left: [], exited_to_right: []}
    |> update_lanes(:lanes_to_left, Enum.member?(greens, :lanes_to_left))
    |> update_lanes(:lanes_to_right, Enum.member?(greens, :lanes_to_right))
  end

  def join_road(road, direction, lanes) when is_list(lanes) do
    Enum.reduce(lanes, road, fn vehicles, road ->
      vehicle_join_road(
        road,
        direction,
        vehicles
        |> Enum.map(fn {v, _} -> {v, 0} end)
      )
    end)
  end

  def vehicle_join_road(road = %{lanes_to_left: [lane1 | other_lanes]}, :right, vehicles) do
    %{road | lanes_to_left: [vehicles ++ lane1 | other_lanes]}
  end

  def vehicle_join_road(road = %{lanes_to_right: [lane1 | other_lanes]}, :left, vehicles) do
    %{road | lanes_to_right: [vehicles ++ lane1 | other_lanes]}
  end

  def to_exit(:lanes_to_left), do: :exited_to_left
  def to_exit(:lanes_to_right), do: :exited_to_right

  def update_lanes(%{road: road} = data, lane_name, can_exit) do
    {lanes, exits} =
      road
      |> Map.get(lane_name)
      |> Enum.map(fn lane ->
        lane
        |> Enum.reverse()
        |> Enum.flat_map_reduce({nil, []}, fn
          vehicle, {vehicle_acc, exited} ->
            case move_forward(vehicle, vehicle_acc, road, can_exit) do
              {[], leader_position} ->
                {[], {road.length, [{elem(vehicle, 0), leader_position} | exited]}}

              {vehicle, leader_position} ->
                {vehicle, {leader_position, exited}}
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

  def move_forward({vehicle, location}, nil, road, can_exit) do
    next_location = location + vehicle.speed

    next_location =
      if can_exit,
        do: next_location,
        else: min(road.length - vehicle_length(), next_location)

    if next_location < road.length do
      {[{vehicle, next_location}], next_location}
    else
      {[], next_location}
    end
  end

  def move_forward({vehicle, location}, leader_pos, road, can_exit) do
    next_location = min(leader_pos - vehicle_length(), location + vehicle.speed)

    next_location =
      if can_exit,
        do: next_location,
        else: min(road.length - vehicle_length(), next_location)

    if next_location < road.length do
      {[{vehicle, next_location}], next_location}
    else
      {[], next_location}
    end
  end
end

defimpl Inspect, for: Traffic.Network.Road do
  @scale Traffic.Network.Road.scale()
  @vehicle_width Traffic.Network.Road.vehicle_length()

  def inspect(road, _opts) do
    "\nName: #{road.name}\n" <>
      String.duplicate("<", road.length * @scale) <>
      inspect_lanes(road.lanes_to_left, :down, road.length) <>
      String.duplicate("=", road.length * @scale) <>
      inspect_lanes(road.lanes_to_right, :up, road.length) <>
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
