defmodule TrafficWeb.Components.LaneDivider do
  use Surface.LiveComponent
  prop(width, :integer)
  prop(lane_width, :integer, default: 0)
  prop(offset, :integer, default: 0)
  prop(index, :integer, default: -1)
  prop(stroke_width, :integer, default: 1)
  prop(stroke, :string, default: "blue")
  prop(solid, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <line
      x1="0"
      y1={(@index + 1) * @lane_width + @offset}
      x2={@width}
      y2={(@index + 1) * @lane_width + @offset}
      stroke={@stroke}
      stroke-width={@stroke_width}
      stroke-dasharray={if(not @solid, do: "8 4")}
    />
    """
  end
end
