defmodule Traffic.Network.Junction do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Network.Road
  alias Traffic.Vehicles.Vehicle

  @type vehicle_in_junction :: %{vehicle: Vehicle.t(), target_road: atom()}

  typedstruct do
    # , [{Road.t(), Road.road_end()}]
    field :roads, %{}, default: %{}
    # field :roads, map(Road.name(), [{Road.t(), Road.road_end()}]), default: %{}

    field :vehicle_in_junction, %{}, default: %{}
  end

  def invert(:right), do: :left
  def invert(:left), do: :right

  def step(%Junction{} = junction) do
    # TODO: should pass through junction
    # TODO: block if junction blocked
    # TODO: block return info on if has space

    road_names =
      junction.roads
      |> Enum.map(fn {name, %{connection: connection}} ->
        {name, connection}
      end)

    roads =
      junction.roads
      |> Enum.map(fn {road_end, %{road: road, connection: connection, light: light} = r} ->
        {road_end, %{r | road: Road.step(road, [{connection, light}], road_names)}}
      end)
      |> Enum.into(%{})

    vehicle_in_junction =
      roads
      |> Enum.map(fn {road_name, %{connection: connection}} ->
        {{road_name, connection}, get_in(roads, [road_name, :road, connection])}
      end)
      |> Enum.into(%{})

    #

    roads =
      roads
      |> Enum.map(fn {name, v} ->
        connection = get_in(roads, [name, :connection])

        connection_data = v.road

        {name, connection} |> IO.inspect()

        vehicles =
          junction.vehicle_in_junction
          |> Enum.flat_map(fn {_, exit_lanes} ->
            exit_lanes
            |> IO.inspect(label: "exit_lanes")
            |> Enum.map(fn vehicles ->
              vehicles
              |> Enum.filter(fn
                {_, _, exit_road} ->
                  exit_road == {name, connection}

                _ ->
                  false
              end)
            end)
          end)
          |> then(fn
            [] ->
              connection_data = v.road
              lanes = Enum.count(Map.from_struct(connection_data.road)[invert(connection)])
              List.duplicate([], lanes)

            a ->
              a
          end)
          |> IO.inspect(label: "vvv")

        road =
          Road.join_road(
            connection_data.road,
            connection,
            vehicles
          )

        # |> IO.inspect(label: "road")

        {name, put_in(v, [:road], road)}
      end)
      |> Enum.into(%{})

    # |> IO.inspect()

    %{
      junction
      | roads: roads,
        vehicle_in_junction: vehicle_in_junction
    }
  end
end

defimpl Inspect, for: Traffic.Network.Junction do
  alias Traffic.Network.Junction
  # "#{match_light(:red, junction.light)}\n" <>
  #   "#{match_light(:yellow, junction.light)}\n" <>
  #   "#{match_light(:green, junction.light)}\n"

  # Kernel.inspect(junction)
  def inspect(%Junction{} = junction, _opts) do
    keys =
      Map.keys(junction.roads)
      |> Enum.sort()

    lanes =
      for k <- keys do
        junction.roads[k]
      end
      |> Enum.map(&Kernel.inspect(&1.road))

    lane_count =
      lanes
      |> Enum.map(&(String.split(&1, "\n") |> Enum.count()))
      |> Enum.max()

    junction_str =
      for k <- keys do
        {junction.vehicle_in_junction[{k, junction.roads[k].connection}],
         arrow(junction.roads[k].connection), junction.roads[k].light}
      end
      |> Enum.reverse()
      |> Enum.flat_map(fn
        {nil, arrow, light} ->
          [
            "|#{row_light(light)}|#{arrow} #{arrow}|#{row_light(light)}"
          ]

        {lanes, arrow, light} ->
          lanes
          |> Enum.map(fn
            [{vehicle, _, _}] ->
              "|#{row_light(light)}|#{arrow}#{vehicle.marker}#{arrow}|#{row_light(light)}"

            [] ->
              "|#{row_light(light)}|#{arrow} #{arrow}|#{row_light(light)}"
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

  def arrow(:left), do: "«"
  def arrow(:right), do: "»"
  # "◉"

  def match_light(light, light) do
    # "◉"
    "•"
  end

  def match_light(_, _) do
    # "◎"
    "○"
  end
end
