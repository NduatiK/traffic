defmodule TrafficWeb.Components.Road do
  use Surface.LiveComponent

  alias TrafficWeb.Components.{Vehicle, Lane}

  prop(class, :string, default: "items-center")
  prop(road, :map)
  data(width, :integer)
  prop(lane_width, :integer)

  slot(default)

  def render(assigns) do
    lane_count = (assigns.road.right |> Enum.count()) + (assigns.road.left |> Enum.count())

    assigns =
      assigns
      |> Map.put(:l_lanes, assigns.road.left |> Enum.count())
      |> Map.put(:r_lanes, assigns.road.right |> Enum.count())
      |> Map.put(:height, lane_count * (assigns.lane_width + 1))
      |> Map.put(:width, assigns.road.length * 100)
      |> Map.put(:lane_color, "#c0c0c0")

    # <g width={@width} height={@height} version="1.1" transform="rotate(-10 50 100) translate(0, 100)">
    ~F"""
    <g width={@width} height={@height} version="1.1">
      <line x1="0" y1="0" x2={@width} y2="0" stroke={@lane_color} stroke-width="5" />

      {!--
      <Vehicle flip={false} x={100} y={@lane_width - 1} color="orange" />

      --}
      <Lane id={Atom.to_string(@road.name) <> "right" }width={@width} road_length={@road.length}
      lane_width={@lane_width}
      flip

      lanes={@road.right} offset={0} />
      <line
        x1={0}
        y1={@r_lanes * Lane.lane_width()}
        x2={@width}
        y2={@r_lanes * Lane.lane_width()}
        stroke={@lane_color}
        stroke-width="2.5"
      />
      <Lane width={@width} road_length={@road.length} lanes={@road.left}
      lane_width={@lane_width}
      id={Atom.to_string(@road.name) <> "left" }
      offset={@r_lanes * (Lane.lane_width() + 1)} />

      <line x1="0" y1={@height} x2={@width} y2={@height} stroke={@lane_color} stroke-width="5" />
    </g>
    """
  end
end
