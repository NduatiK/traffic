defmodule Traffic.Network do
  alias Traffic.Network.{Road, Junction, Graph}

  def build_network() do
    {:ok, road_1} = Agent.start_link(fn -> Road.preloaded(:road_1) end)
    {:ok, road_2} = Agent.start_link(fn -> Road.preloaded(:road_2) end)

    {:ok, junction_1} =
      Agent.start_link(fn ->
        %Junction{roads: %{}}
      end)

    {:ok, junction_2} =
      Agent.start_link(fn ->
        %Junction{roads: %{}}
      end)

    network =
      Graph.create()
      |> Graph.add_junction(junction_1)
      |> Graph.add_junction(junction_2)
      |> Graph.add_road(road_1, junction_1, junction_2)
  end

  def step_junction(graph, junction) do
    # Step self
    Agent.get_and_update(junction, fn junction ->
      {junction, output} = Junction.step(junction)

      junction
    end)
  end
end
