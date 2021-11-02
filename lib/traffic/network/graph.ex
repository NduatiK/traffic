defmodule Traffic.Network.Graph do
  alias Graph

  @moduledoc """
  Tag each item with grid data
  for plotting.

  https://hexdocs.pm/libgraph/Graph.html


  Rendering road
  https://github.com/moomerman/flappy-phoenix/blob/master/lib/flappy_phoenix_web/templates/game/index.html.leex

  SVG?
  https://twitter.com/stevegraham/status/1255566636838338561 = Polyline
  https://twitter.com/lucianparvu/status/1109087821581742080

  # Rendering cars in svg
  https://www.youtube.com/watch?v=p7Rav3Vm7uY
  https://github.com/lewis500/town/blob/master/app/app.coffee


  https://github.com/ashiqur-rony/css-traffic-simulator
  https://ashiqur.com/traffic-simulation-with-html-css/


  # Linear regression
  https://dev.to/tiemen/linear-regression-with-elixir-phoenix-and-liveview-part-ii-29c7
  https://github.com/tmw/linreg
  https://www.poeticoding.com/liveview-click-event-and-offsetx-offsety-coordinates/

  """

  def create() do
    # One way roads exist
    Graph.new(type: :directed)
  end

  def add_road(graph, road_pid) do
    add_road(graph, road_pid, create_nil_junction(), create_nil_junction())
  end

  def add_road(graph, road_pid, junction_1) do
    add_road(graph, road_pid, junction_1, create_nil_junction())
  end

  def add_road(graph, road, junction_1, junction_2) do
    # nil junction that immediately turns cars back

    graph
    |> Graph.add_edge(junction_1, junction_2, label: {road, :green})
  end

  def add_junction(graph, junction) do
    # replace nil junction
    graph
    |> Graph.add_vertex(junction, [])
  end

  def add_junction(graph, road_1, road_2, junction) do
    # replace nil junction
    graph
    |> Graph.add_vertex(junction, [])
  end

  def create_nil_junction() do
    nil
  end

  # def junctions(graph), do: Graph.split_edge()
  #

  def junctions(graph), do: Graph.vertices(graph)
  def roads(graph), do: Graph.edges(graph)
  def roads(graph, junction), do: Graph.edges(graph, junction)

  def left_junction(%Graph.Edge{v1: junction}), do: junction
  def right_junction(%Graph.Edge{v2: junction}), do: junction
  def side_of_connection(junction, %Graph.Edge{v2: junction}), do: :right
  def side_of_connection(junction, %Graph.Edge{v1: junction}), do: :left

  def junction_roads(graph, junction) do
    graph
    |> roads(junction)
    |> Enum.reduce(%{}, fn road, acc ->
      side =
        junction
        |> side_of_connection(road)

      acc
      |> Map.update(side, [road], fn existing_values ->
        existing_values ++ [road]
      end)
    end)
  end
end
