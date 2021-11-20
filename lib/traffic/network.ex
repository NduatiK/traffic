defmodule Traffic.Network do
  alias Traffic.Network.{Road, Junction, Graph, Config}

  def start_simulation(name) do
    Traffic.Simulation.start_simulation(name, [])
  end

  def start_road2(name, junction1, junction2) do
    Traffic.Network.Manager.start_road(name, junction1, junction2)
  end

  def start_junction2(name, x, y) do
    Traffic.Network.Manager.start_junction(name, x, y)
  end

  def build_network(name) do
    {:ok, junction_1} = start_junction2(name, 100, 100)
    {:ok, junction_2} = start_junction2(name, 500, 100)
    {:ok, junction_3} = start_junction2(name, 700, 300)
    {:ok, junction_4} = start_junction2(name, 500, 500)
    {:ok, junction_5} = start_junction2(name, 100, 500)

    {:ok, _road_0} = start_road2(name, junction_1, junction_2)
    {:ok, _road_1} = start_road2(name, junction_2, junction_3)
    {:ok, _road_2} = start_road2(name, junction_3, junction_4)
    {:ok, _road_3} = start_road2(name, junction_4, junction_5)
    {:ok, _road_4} = start_road2(name, junction_5, junction_1)
    {:ok, _road_5} = start_road2(name, junction_4, junction_2)
  end

  def start_road(name, %Config{} = config) do
    Agent.start_link(fn -> Road.preloaded(name, config) end, name: name)
  end

  def start_junction(x, y) do
    Agent.start_link(fn -> %Junction{roads: %{}, x: x, y: y} end)
  end

  def build_network(config) do
    {:ok, road_1} = start_road(:road_1, config)
    {:ok, road_2} = start_road(:road_2, config)
    {:ok, road_3} = start_road(:road_3, config)
    {:ok, road_4} = start_road(:road_4, config)
    {:ok, road_5} = start_road(:road_5, config)
    {:ok, road_6} = start_road(:road_6, config)

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

  def step_junction(graph, junction_pid, config) do
    # Step self
    Agent.get_and_update(junction_pid, fn junction ->
      roads =
        graph
        |> Graph.junction_roads(junction_pid)
        |> get_values()

      {junction, output} = Junction.step(junction, roads, config)

      {output, junction}
    end)
  end

  def get_values(roads) do
    #  %{
    #   a: %{road: road_a, connection: :right},
    #   b: %{road: road_b, connection: :left}
    # }
    roads
    |> Map.to_list()
    |> Enum.flat_map(fn {k, v} ->
      v
      |> Enum.map(fn edge ->
        road = Agent.get(edge.label, fn a -> a end)

        {road.name,
         %{
           road: road,
           connection: k
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
          Agent.get(road_edge.label, fn road ->
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

  def step(graph, %Config{} = config) do
    graph
    |> Graph.junctions()
    |> Enum.map(fn junction ->
      roads = step_junction(graph, junction, config)

      roads
      |> Enum.map(fn {k, road} ->
        Agent.update(k, fn _ -> road.road end)
      end)
    end)

    graph
  end

  def get_processes(network) do
    junctions =
      network
      |> Graph.junctions()

    roads =
      network
      |> Graph.roads()
      |> Enum.map(fn road -> road.label end)

    junctions ++ roads
  end
end
