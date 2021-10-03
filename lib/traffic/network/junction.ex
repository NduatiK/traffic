defmodule Traffic.Network.Junction do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Network.Road
  alias Traffic.Vehicles.Vehicle

  @type vehicle_in_junction :: %{vehicle: Vehicle.t(), target_road: atom()}

  typedstruct do
    field :left_light, :red | :yellow | :green
    field :right_light, :red | :yellow | :green
    # field :roads, list(Road.t()), default: []
    field :left_road, Road.t()
    field :right_road, Road.t()

    field :vehicle_in_junction,
          %{
            left: [vehicle_in_junction] | nil,
            right: [vehicle_in_junction] | nil
          },
          default: %{left: nil, right: nil}
  end

  def step(%Junction{} = junction) do
    # TODO: should pass through junction
    # TODO: block if junction blocked
    # TODO: block return info on if has space

    left_road_ = Road.step(junction.left_road, [:lanes_to_right])
    right_road_ = Road.step(junction.right_road, [:lanes_to_left])

    in_junction_from_left =
      left_road_.exited_to_right

    in_junction_from_right =
      right_road_.exited_to_left

    right_road =
      Road.join_road(
        right_road_.road,
        :left,
        junction.vehicle_in_junction.left
      )

    left_road =
      Road.join_road(
        left_road_.road,
        :right,
        junction.vehicle_in_junction.right
      )

    %{
      junction
      | left_road: left_road,
        right_road: right_road,
        vehicle_in_junction: %{
          left: in_junction_from_left,
          right: in_junction_from_right
        }
    }
  end
end

defimpl Inspect, for: Traffic.Network.Junction do
  alias Traffic.Network.Road
  # "#{match_light(:red, junction.light)}\n" <>
  #   "#{match_light(:yellow, junction.light)}\n" <>
  #   "#{match_light(:green, junction.light)}\n"

  # Kernel.inspect(junction)
  def inspect(junction, _opts) do
    lanes =
      [junction.left_road, junction.right_road]
      |> Enum.map(&Kernel.inspect(&1))

    lane_count =
      lanes
      |> Enum.map(&(String.split(&1, "\n") |> Enum.count()))
      |> Enum.max()

    junction_str =
      [
        {junction.vehicle_in_junction.right, "«"},
        {junction.vehicle_in_junction.left, "»"}
      ]
      |> Enum.flat_map(fn {lanes, arrow} ->
        lanes
        |> Enum.map(fn
          [{vehicle, _}] ->
            "|#{row_light(junction.left_light)}|#{arrow}#{vehicle.marker}#{arrow}|#{row_light(junction.right_light)}"

          [] ->
            "|#{row_light(junction.left_light)}|#{arrow} #{arrow}|#{row_light(junction.right_light)}"
        end)
      end)
      |> Enum.intersperse("")

    junction_str = ["", "", "" | junction_str]

    max_width =
      junction_str
      |> Enum.map(&String.length/1)
      |> Enum.max()

    junction_str =
      (junction_str ++ List.duplicate("|", lane_count - Enum.count(junction_str)))
      |> Enum.map(fn str ->
        String.pad_trailing(str, max_width) <> "|"
      end)

    lanes
    # ["====\n====", "++++\n++++"]
    |> Enum.map(&String.split(&1, "\n"))
    # [["====","===="], ["++++","++++"]]
    |> Enum.intersperse(junction_str)
    # [["====","===="], ["◉","◉"], ["++++","++++"]]
    |> Enum.zip()
    # [{"====","◉","++++"}, {"====", "◉","++++"}]
    |> Enum.map(
      &(Tuple.to_list(&1)
        #     # [["====","◉","++++"], ["====","◉","++++"]]
        |> Enum.join())
      #     # [["====◉++++"], ["====◉++++"]]
    )
    |> Enum.join("\n")

    # "====◉++++\n====◉++++"
  end

  def row_light(light) do
    match_light(:red, light) <>
      match_light(:yellow, light) <>
      match_light(:green, light)
  end

  def match_light(light, light) do
    # "◉"
    "•"
  end

  def match_light(_, _) do
    # "◎"
    "○"
  end
end
