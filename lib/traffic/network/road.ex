defmodule Traffic.Network.Road do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Vehicles.Vehicle

  typedstruct do
    # Location awareness
    field :length, integer(), enforce: true
    field :lanes_to_right, list(list({pid(), integer()})), default: []
    field :lanes_to_left, list({pid(), integer()}), default: []
  end

  def preloaded() do
    %Road{
      length: 10,
      lanes_to_right: [
        [{Vehicle.random(), 3}, {Vehicle.random(), 5}, {Vehicle.random(), 6}]
      ],
      lanes_to_left: [
        [
          {Vehicle.random(), 0},
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
      |> Enum.map(
        &Enum.flat_map(&1, fn
          {vehicle, location} when location + vehicle.speed < road.length - 1 ->
            [{vehicle, location + vehicle.speed}]

          {_pid, _} ->
            []
        end)
      )

    Map.put(road, lane_name, lanes)
  end
end

defimpl Inspect, for: Traffic.Network.Road do
  def inspect(road, _opts) do
    String.duplicate("=", road.length) <>
      inspect_lanes(road.lanes_to_left, :down, road.length) <>
      String.duplicate("=", road.length) <>
      inspect_lanes(road.lanes_to_right, :up, road.length) <>
      String.duplicate("=", road.length)
  end

  def inspect_lanes(lanes, direction, length) do
    Enum.map(lanes, &inspect_vehicles(direction, &1, length))
    |> Enum.intersperse("\n" <> String.duplicate("·", length))
    |> Enum.join()
    |> Kernel.<>("\n")
  end

  def inspect_vehicles(:down = direction, vehicles, length) do
    do_inspect_vehicles(direction, vehicles)
    |> String.trim_leading("\n")
    |> String.reverse()
    |> String.pad_leading(length)
    |> then(&("\n" <> &1))
  end

  def inspect_vehicles(:up = direction, vehicles, _) do
    do_inspect_vehicles(direction, vehicles)
  end

  def do_inspect_vehicles(direction, vehicles) do
    vehicles
    |> Enum.reduce({"\n", -1}, fn {vehicle, location}, {acc_str, position} ->
      {
        acc_str <>
          String.duplicate(" ", max(0, location - position - 1)) <> vehicle.marker,
        #  String.duplicate(" ", max(0, location - position - 1)) <> vehicle_art(direction),
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
