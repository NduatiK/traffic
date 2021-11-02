defmodule TrafficWeb.Components.Lofi.Road do
  use Surface.LiveComponent

  alias TrafficWeb.Components.Lofi.{Vehicle, Lane, LaneDivider}

  prop(class, :string, default: "items-center")
  prop(road, :map)
  prop(from, :tuple)
  prop(to, :tuple)
  prop(x, :integer, default: 0)
  prop(y, :integer, default: 0)

  data(height, :integer)
  data(length, :integer, default: 200)
  data(angle, :integer, default: 20)
  # data(angle, :integer, default: 0)
  prop(lane_width, :integer)

  data lane_color, :string, default: "#c0c0c0"
  slot(default)

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(height: 3)
      |> assign(
        angle:
          :math.atan2(
            elem(assigns.from, 1) - elem(assigns.to, 1),
            elem(assigns.from, 0) - elem(assigns.to, 0)
          ) *
            180 / :math.pi()
      )
      |> assign(
        length:
          :math.sqrt(
            :math.pow(elem(assigns.from, 1) - elem(assigns.to, 1), 2) +
              :math.pow(elem(assigns.from, 0) - elem(assigns.to, 0), 2)
          )
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <g transform={"translate(#{elem(assigns.to, 0)}, #{elem(assigns.to, 1) - @height / 2}) rotate(#{@angle}, 0, #{@height / 2})"}
    overflow="visible" >
      <Lane
        width={@length}
        road_length={@road.length}
        lanes={@road.right}
        direction="right"
        lane_width={@lane_width}
        id={Atom.to_string(@road.name) <> "right"}
        flip
        road_name={Atom.to_string(@road.name)}
        offset={1}
      />
      <LaneDivider width={@length} lane_width={@lane_width} stroke_width={2} solid offset={4} />
      <Lane
        width={@length}
        road_length={@road.length}
        lanes={@road.left}
        road_name={Atom.to_string(@road.name)}
        direction="left"
        lane_width={@lane_width}
        id={Atom.to_string(@road.name) <> "left"}
        offset={8}
      />
    </g>
    """
  end
end
