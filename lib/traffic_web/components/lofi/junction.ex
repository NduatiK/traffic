defmodule TrafficWeb.Components.Lofi.Junction do
  use Surface.LiveComponent

  alias TrafficWeb.Components.Lofi.{Vehicle, Lane, LaneDivider}
  alias Traffic.Network.JunctionServer

  prop(class, :string, default: "items-center")
  prop(junction, :any)
  prop(network_id, :any)

  data(color, :string, default: "#869d9d")
  data(x, :integer, default: 0)
  data(y, :integer, default: 0)

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @topic "junction_"

  @impl true
  def update(assigns, socket) do
    socket =
      if connected?(socket) do
        socket
        |> assign(assigns)
        |> assign_new(:subscribed?, fn ->
          TrafficWeb.Endpoint.subscribe(@topic <> "#{inspect(assigns.junction)}")
          true
        end)
        |> load_location(assigns.junction)
      else
        socket
        |> assign(assigns)
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # <g width={@road.length * 100} height={@height}>
    ~F"""
    <circle cx={@x} cy={@y} r="8" fill="#efefef" stroke="#869d9d" stroke-width={1} />
    """
  end

  def load_location(socket, junction) do
    {x, y} = JunctionServer.get_location(junction)

    socket
    |> assign(x: x)
    |> assign(y: y)
  end
end
