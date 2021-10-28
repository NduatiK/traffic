defmodule TrafficWeb.Components.Road do
  use Surface.LiveComponent

  alias TrafficWeb.Components.{Vehicle, Lane, LaneDivider}

  prop(class, :string, default: "items-center")
  prop(road, :map)
  data(height, :integer)
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
    # <g width={@road.length * 100} height={@height} version="1.1" transform="rotate(-10 50 100) translate(0, 100)">
    # height={(Enum.count(@road.right) + Enum.count(@road.left)) * (@lane_width + 1)}
    ~F"""
    <g width={@road.length * 100} height={@height}>
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
      --}
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
