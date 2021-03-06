defmodule TrafficWeb.Components.Lofi.LaneDivider do
  use Surface.Component
  prop(width, :integer)
  prop(lane_width, :integer, default: 0)
  prop(offset, :integer, default: 0)
  prop(index, :integer, default: -1)
  prop(stroke_width, :integer, default: 1)
  prop(stroke, :string, default: "#C2C2C2")
  prop(solid, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <line
      x1="0"
      y1={2}
      x2={@width}
      y2={2}
      stroke={@stroke}
      stroke-width={@stroke_width}
      stroke-dasharray={if(not @solid, do: "8 4")}
    />
    """
  end
end
