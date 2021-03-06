defmodule TrafficWeb.Components.RoadNetwork do
  use Surface.LiveComponent

  alias TrafficWeb.Components.{Vehicle, Lane, LaneDivider, Road, Junction}

  data width, :integer, default: 2000
  data height, :integer, default: 1010
  data padding, :integer, default: 50

  prop network, :map
  data junctions, :list, default: []
  data roads, :list, default: []

  def update(assigns, socket) do
    {junctions, roads} =
      if connected?(socket) do
        Traffic.Network.Server.get_compiled(Traffic.Network.Server)
      else
        {[], []}
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(junctions: junctions, roads: roads)

    {:ok, socket}
  end

  @impl true
  def mount(socket) do
    {junctions, roads} =
      if connected?(socket) do
        Traffic.Network.Server.get_compiled(Traffic.Network.Server)
      else
        {[], []}
      end

    socket =
      socket
      |> assign(junctions: junctions, roads: roads)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <svg
      x="0px"
      y="0px"
      width={@width + @padding * 2}
      height={@height + @padding * 2}
      viewBox={"#{-@padding} #{-@padding} #{@width + @padding} #{@height + @padding}"}
      xml:space="preserve"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
    >
      {#for {junction, id} <- Enum.with_index(@junctions)}
        <Junction id={id} junction={junction} />
      {/for} {#for {road, id} <- Enum.with_index(@roads)}
        <Road id={"road-#{id}"} road={road.road} from={road.from} to={road.to} lane_width={20} />
      {/for}
    </svg>
    """
  end
end
