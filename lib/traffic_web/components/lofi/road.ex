defmodule TrafficWeb.Components.Lofi.Road do
  use Surface.LiveComponent

  alias TrafficWeb.Components.Lofi.{Vehicle, Lane, LaneDivider}
  alias Traffic.Network.JunctionServer
  alias Traffic.Network.RoadServer

  prop(class, :string, default: "items-center")
  prop(road_pid, :any)
  prop(from_junction, :pid)
  prop(to_junction, :pid)

  data(height, :integer)
  data(length, :integer, default: 200)
  data(angle, :integer, default: 20)
  data(lights, :map)
  prop(lane_width, :integer)
  data(road, :map)
  prop(arterial, :boolean)

  data(lane_color, :string, default: "#c0c0c0")
  slot(default)

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {x1, y1} = JunctionServer.get_location(socket.assigns.from_junction)

    {x2, y2} = JunctionServer.get_location(socket.assigns.to_junction)

    {road, lights} = RoadServer.get_road_and_lights(socket.assigns.road_pid)

    socket =
      socket
      |> assign(from: {x1, y1})
      |> assign(to: {x2, y2})
      |> assign(height: 3)
      |> assign(road: road)
      |> assign(lights: lights)
      |> assign(angle: Traffic.Geometry.angle({x2, y2}, {x1, y1}))
      |> assign(length: Traffic.Geometry.distance({x1, y1}, {x2, y2}))
      |> assign_new(:subscribed?, fn ->
        TrafficWeb.Endpoint.subscribe("road_#{inspect(assigns.road_pid)}")
        true
      end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    # data[name]={@road.name}
    ~F"""
    <g
      :if={@road}
      style={"transform: translate(#{elem(assigns.from, 0)}px, #{elem(assigns.from, 1) - @height / 2}px) rotate(#{@angle}deg)"}
      overflow="visible"
    >
      <!--
    {inspect(self())}
    -->

      <Lane
        width={@length}
        road_length={@road.length}
        lanes={@road.right}
        direction="right"
        lane_width={@lane_width}
        light={@lights.right}
        id={inspect(@road.name) <> "right"}
        road_name={inspect(@road.name)}
        offset={1}
      />
      <LaneDivider width={@length} lane_width={@lane_width} stroke_width={if @arterial, do: 5, else: 3} solid offset={4} />
      <Lane
        flip
        width={@length}
        road_length={@road.length}
        lanes={@road.left}
        light={@lights.left}
        road_name={inspect(@road.name)}
        direction="left"
        lane_width={@lane_width}
        id={Atom.to_string(@road.name) <> "left"}
        offset={8}
      />
      <g class="z-10"><rect width={5} height={4} x={7} fill={render_light(@lights.left)} /></g>
      <g class="z-10"><rect width={5} height={4} x={@length - 10} fill={render_light(@lights.right)} /></g>
    </g>
    """

    # <text x="0" y="0" class="text-sm">L</text>
    # <text x="0" y="0" class="text-sm">L{Atom.to_string(@road.name) }{inspect(@road_pid)}</text>
    # s
  end

  def render_light(:red), do: "red"
  def render_light(:yellow), do: "yellow"
  def render_light(:green), do: "#78BB7B"
end
