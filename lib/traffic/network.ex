defmodule Traffic.Network do
  alias Traffic.Network.{Road, Junction, Graph}

  def start_road(name) do
    Agent.start_link(fn -> Road.preloaded(name) end, name: name)
  end

  def start_junction(x, y) do
    Agent.start_link(fn -> %Junction{roads: %{}, x: x, y: y} end)
  end

  def build_network() do
    {:ok, road_1} = start_road(:road_1)
    {:ok, road_2} = start_road(:road_2)
    {:ok, road_3} = start_road(:road_3)
    {:ok, road_4} = start_road(:road_4)
    {:ok, road_5} = start_road(:road_5)
    {:ok, road_6} = start_road(:road_6)

    {:ok, junction_1} = start_junction(100, 100)
    {:ok, junction_2} = start_junction(500, 100)
    {:ok, junction_3} = start_junction(700, 300)
    {:ok, junction_4} = start_junction(500, 500)
    {:ok, junction_5} = start_junction(100, 500)

    Graph.create()
    |> Graph.add_junction(junction_1)
    |> Graph.add_junction(junction_2)
    |> Graph.add_junction(junction_3)
    |> Graph.add_junction(junction_4)
    |> Graph.add_junction(junction_5)
    |> Graph.add_road(road_1, junction_1, junction_2)
    |> Graph.add_road(road_2, junction_2, junction_3)
    |> Graph.add_road(road_3, junction_3, junction_4)
    |> Graph.add_road(road_4, junction_4, junction_5)
    |> Graph.add_road(road_5, junction_5, junction_1)
    |> Graph.add_road(road_6, junction_4, junction_2)
  end

  # def step_graph

  def step_junction(graph, junction_pid) do
    # Step self
    Agent.get_and_update(junction_pid, fn junction ->
      roads =
        graph
        |> Graph.junction_roads(junction_pid)
        |> get_values()

      {junction, output} = Junction.step(junction, roads)

      {output, junction}
    end)
  end

  def get_values(roads) do
    #  %{
    #   a: %{road: road_a, connection: :right, light: :red},
    #   b: %{road: road_b, connection: :left, light: :red}
    # }
    roads
    |> Map.to_list()
    |> Enum.flat_map(fn {k, v} ->
      v
      |> Enum.map(fn edge ->
        road = Agent.get(elem(edge.label, 0), fn a -> a end)

        {road.name,
         %{
           road: road,
           connection: k,
           light: elem(edge.label, 1)
         }}
      end)
    end)
    |> Enum.into(%{})
  end

  def compile_network(graph) do
    junctions_map =
      graph
      |> Graph.junctions()
      |> Enum.map(
        &Task.async(fn ->
          Agent.get(&1, fn j ->
            {&1, {j, {j.x, j.y}}}
          end)
        end)
      )
      |> Enum.map(&Task.await(&1))
      |> Enum.into(%{})

    junctions =
      junctions_map
      |> Map.values()
      |> Enum.map(&elem(&1, 0))

    roads =
      graph
      |> Graph.roads()
      |> Enum.map(fn road_edge ->
        Task.async(fn ->
          Agent.get(elem(road_edge.label, 0), fn road ->
            %{
              road: road,
              from: Map.get(junctions_map, road_edge.v1) |> elem(1),
              to: Map.get(junctions_map, road_edge.v2) |> elem(1)
            }
          end)
        end)
      end)
      |> Enum.map(&Task.await(&1))

    {junctions, roads}
  end

  def step(graph) do
    graph
    |> Graph.junctions()
    |> Enum.map(fn junction ->
      roads = step_junction(graph, junction)

      roads
      |> Enum.map(fn {k, road} ->
        Agent.update(k, fn _ -> road.road end)
      end)
    end)

    graph
  end
end
