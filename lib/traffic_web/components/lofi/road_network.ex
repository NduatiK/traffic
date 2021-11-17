defmodule TrafficWeb.Components.Lofi.RoadNetwork do
  use Surface.LiveComponent

  alias TrafficWeb.Components.Lofi.{Vehicle, Lane, LaneDivider, Road, Junction}

  data(padding, :integer, default: 50)

  prop(network, :map)
  prop(network_id, :any)
  data(junctions, :list, default: [])
  data(roads, :list, default: [])

  def update(assigns, socket) do
    {junctions, roads} =
      if connected?(socket) do
        # Traffic.Network.Manager.get_graph(socket.assigns.network_id)
        # IO.inspect(assigns.network)

        {[], []}
        # Traffic.Network.Server.get_compiled(Traffic.Network.Server)
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
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <svg x="0px" y="0px">
      {#for junction <- Graph.vertices(@network)}
        <Junction id={"junction_#{inspect(junction)}"} network_id={@network_id} junction={junction} />
      {/for} {#for road <- Graph.edges(@network)}
        <Road
          id={"road_#{inspect(road.label)}"}
          road_pid={road.label}
          from_junction={road.v1}
          to_junction={road.v2}
          lane_width={30}
        />
      {/for}
    </svg>
    """
  end
end
