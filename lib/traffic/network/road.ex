defmodule Traffic.Network.Road do
  use TypedStruct
  alias __MODULE__

  typedstruct do
    # Location awareness
    field :length, integer(), enforce: true

    field :vehicles_up, list(list({pid(), integer()})),
      default: [
        # [{0, 0}, {0, 1}, {0, 4}, {0, 8}, {1, 9}],
        [{0, 3}, {0, 5}, {0, 6}]
      ]

    # default: []

    field :vehicles_down, list({pid(), integer()}),
      default: [
        [{0, 0}, {0, 1}, {0, 4}, {0, 8}, {1, 9}]
      ]
  end
end

defimpl Inspect, for: Traffic.Network.Road do
  def inspect(road, _opts) do
    String.duplicate("=", road.length) <>
      inspect_lanes(road.vehicles_down, :down) <>
      String.duplicate("-", road.length) <>
      inspect_lanes(road.vehicles_up, :up) <>
      String.duplicate("=", road.length)
  end

  def inspect_lanes(lanes, direction) do
    Enum.map(lanes, &inspect_vehicles(direction, &1))
    |> Enum.join()
    |> Kernel.<>("\n")
  end

  def inspect_vehicles(:down = direction, vehicles) do
    do_inspect_vehicles(direction, vehicles)
    |> String.trim_leading()
    |> String.reverse()
    |> then(&("\n" <> &1))
  end

  def inspect_vehicles(:up = direction, vehicles) do
    do_inspect_vehicles(direction, vehicles)
  end

  def do_inspect_vehicles(direction, vehicles) do
    vehicles
    |> Enum.reduce({"\n", -1}, fn {_pid, location}, {acc_str, position} ->
      {acc_str <>
         String.duplicate(" ", max(0, location - position - 1)) <> vehicle_art(direction),
       location}
    end)
    |> elem(0)

    # |> Kernel.<>("\n")
  end

  def vehicle_art(:down) do
    "◄"
  end

  def vehicle_art(:up) do
    "►"
  end
end
