defmodule TrafficWeb.Pages.Map do
  use TrafficWeb, :surface_view_helpers
  alias TrafficWeb.Components.{Road}

  data width, :integer, default: 1000
  data height, :integer, default: 510
  data road, :map, default: Traffic.Network.Road.preloaded()
  @rate 10

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, @rate)
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
    road = Traffic.Network.Road.step(socket.assigns.road, []).road
    socket = assign(socket, :road, road)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <svg
      x="0px"
      y="0px"
      width={@width}
      height={@height}
      viewBox="0 0 {@width} {@height}"
      enable-background="new 0 0 {@width} 510"
      xml:space="preserve"
    >
      <defs>
        {{:safe, TrafficWeb.Components.Vehicle.mustang()}}
      </defs>
      <Road id="1" road={@road } lane_width={30} />
    </svg>
    """
  end
end
