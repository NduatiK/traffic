defmodule TrafficWeb.Components.Road do
  use Surface.LiveComponent

  alias TrafficWeb.Components.{Vehicle, Lane, LaneDivider}

  prop(class, :string, default: "items-center")
  prop(road, :map)
  prop(from, :tuple)
  prop(to, :tuple)
  prop(x, :integer, default: 0)
  prop(y, :integer, default: 0)

  data(height, :integer)
  data(angle, :integer, default: 20)
  # data(angle, :integer, default: 0)
  prop(lane_width, :integer)

  data lane_color, :string, default: "#c0c0c0"
  slot(default)

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(
        height:
          (Enum.count(assigns.road.right) + Enum.count(assigns.road.left)) *
            (assigns.lane_width + 1)
      )
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <g
    transform={"translate(#{@x}, #{@y - @height/2}) rotate(#{@angle}, 0, #{@height/2})"}

      >
      <LaneDivider
        id={"top" <> Atom.to_string(@road.name)}
        width={@road.length * 100}
        lane_width={@lane_width}
        stroke={@lane_color}
        stroke_width="5"
        solid
      />
      <Lane
        width={@road.length * 100}
        road_length={@road.length}
        lanes={@road.right}
        direction="right"
        lane_width={@lane_width}
        id={Atom.to_string(@road.name) <> "right"}
        flip
      />
      <LaneDivider
        id={"middle" <> Atom.to_string(@road.name)}
        width={@road.length * 100}
        lane_width={@lane_width}
        offset={Enum.count(@road.right) * @lane_width}
        stroke={@lane_color}
        stroke_width="2.5"
        solid
      />
      <Lane
        width={@road.length * 100}
        road_length={@road.length}
        lanes={@road.left}
        direction="left"
        lane_width={@lane_width}
        id={Atom.to_string(@road.name) <> "left"}
        offset={Enum.count(@road.right) * (@lane_width + 1)}
      />
      <LaneDivider
        id={"bottom" <> Atom.to_string(@road.name)}
        width={@road.length * 100}
        index={-1}
        lane_width={@lane_width}
        offset={@height}
        stroke={@lane_color}
        stroke_width="5"
        solid
      />
    </g>
    """
  end
end
