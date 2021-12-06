defmodule TrafficWeb.Components.Junction do
  use Surface.LiveComponent

  prop(class, :string, default: "items-center")
  prop(junction, :map)

  data lane_color, :string, default: "#c0c0c0"

  @impl true
  def render(assigns) do
    # <g width={@road.length * 100} height={@height}>
    ~F"""
    <circle cx={@junction.x} cy={@junction.y} r="50" fill="#869d9d" />
    """
  end
end
