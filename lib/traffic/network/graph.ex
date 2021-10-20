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
  end

  def add_road(graph, road_pid) do
    # nil junction that immediately turns cars back
  end

  def add_junction(graph, road_pid, junction) do
    # replace nil junction
  end
end
