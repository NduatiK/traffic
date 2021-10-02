defmodule Traffic.Network.Road do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Vehicles.Vehicle
  def scale, do: 10
  def vehicle_length, do: 0.2

  typedstruct do
    # Location awareness
    field :length, integer(), enforce: true
    field :lanes_to_right, list(list({pid(), float()})), default: []
    field :lanes_to_left, list({pid(), float()}), default: []
  end

  def preloaded() do
    %Road{
      length: 10,
      lanes_to_right: [
        [{Vehicle.random(), 3}, {Vehicle.random(), 5}, {Vehicle.random(), 6}]
      ],
      lanes_to_left: [
        [
          {Vehicle.random(), 0.5},
          {Vehicle.random(), 1},
          {Vehicle.random(), 2},
          {Vehicle.random(), 4},
          {Vehicle.random(), 8},
          {Vehicle.random(), 9}
        ],
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

  def step(%Road{} = road) do
    road
    |> update_lanes(:lanes_to_left)
    |> update_lanes(:lanes_to_right)
  end

  def update_lanes(road, lane_name) do
    lanes =
      road
      |> Map.get(lane_name)
      |> Enum.map(fn lane ->
        lane
        |> Enum.reverse()
        |> Enum.flat_map_reduce(nil, fn
          vehicle, vehicle_acc ->
            res = move_forward(vehicle, vehicle_acc, road)

            # case res do
            #   {[], at} -> {[], at}
            #   {[{veh, loc}], at} -> {{veh.marker, loc}, at}
            # end
            # |> IO.inspect()

            res
        end)
        |> elem(0)
        |> Enum.reverse()
      end)

    Map.put(road, lane_name, lanes)
  end

  def move_forward({vehicle, location}, nil, road) do
    next_location = location + vehicle.speed

    if next_location < road.length do
      {[{vehicle, next_location}], next_location}
    else
      {[], next_location}
    end
  end

  def move_forward({vehicle, location}, leader_pos, road) do
    next_location = min(leader_pos - vehicle_length(), location + vehicle.speed)

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
    String.duplicate("Ξ", road.length * @scale) <>
      inspect_lanes(road.lanes_to_left, :down, road.length) <>
      String.duplicate("=", road.length * @scale) <>
      inspect_lanes(road.lanes_to_right, :up, road.length) <>
      String.duplicate("Ξ", road.length * @scale)
  end

  def inspect_lanes(lanes, direction, length) do
    Enum.map(lanes, &inspect_vehicles(direction, &1, length))
    |> Enum.intersperse("\n" <> String.duplicate("·", length * @scale))
    |> Enum.join()
    |> Kernel.<>("\n")
  end

  def inspect_vehicles(:down = direction, vehicles, length) do
    do_inspect_vehicles(direction, vehicles)
    |> String.trim_leading("\n")
    |> String.reverse()
    |> String.pad_leading(length * @scale)
    |> then(&("\n" <> &1))
  end

  def inspect_vehicles(:up = direction, vehicles, _) do
    do_inspect_vehicles(direction, vehicles)
  end

  def do_inspect_vehicles(direction, vehicles) do
    vehicles
    |> Enum.reduce({"\n", -@vehicle_width}, fn {vehicle, location}, {acc_str, prev_position} ->
      marker = vehicle.marker
      # marker = vehicle_art(direction)

      {
        acc_str <>
          String.duplicate(
            " ",
            round(max(0, (location - prev_position - @vehicle_width) * @scale))
          ) <>
          String.duplicate("◈", round(@vehicle_width * @scale)),
        # marker,
        location
      }
    end)
    |> elem(0)
  end

  def vehicle_art(:down) do
    "◄"
  end

  def vehicle_art(:up) do
    "►"
  end
end
