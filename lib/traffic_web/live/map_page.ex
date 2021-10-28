defmodule TrafficWeb.Pages.Map do
  use TrafficWeb, :surface_view_helpers
  alias TrafficWeb.Components.{Road, RoadNetwork, Junction}

  data width, :integer, default: 2000
  data height, :integer, default: 1010
  data padding, :integer, default: 50
  # data width, :integer, default: 1000
  # data height, :integer, default: 510
  data graph, :map

  @rate round(1000 / 24)
  # @rate round(48000 / 24)

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, @rate)

    socket =
      socket
      |> assign(graph: Traffic.Network.Server.get(Traffic.Network.Server))

    {:ok, socket}
  end

  @impl true
  def handle_params(a, url, socket) do
    %URI{
      path: path
    } = URI.parse(url)

    socket =
      socket
      |> assign(path: path)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @rate)

    send_update(RoadNetwork, id: "network")

    # socket = assign(socket, :road, road)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    # enable-background={"new 0 0 #{@width} 510"}
    ~F"""
    <svg
      x="0px"
      y="0px":
      width={@width + @padding * 2}
      height={@height + @padding * 2}
      viewBox={"#{-@padding} #{-@padding} #{@width + @padding} #{@height + @padding}"}
      xml:space="preserve"
    >
      <defs>
        {{:safe, TrafficWeb.Components.Vehicle.mustang()}}
      </defs>
      <RoadNetwork id="network" network={@graph} />
    </svg>
    """
  end
end
