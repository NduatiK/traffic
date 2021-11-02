defmodule TrafficWeb.Components.Lofi.Junction do
  use Surface.LiveComponent

  alias TrafficWeb.Components.Lofi.{Vehicle, Lane, LaneDivider}

  prop(class, :string, default: "items-center")
  prop(junction, :map)

  data lane_color, :string, default: "#c0c0c0"

  # @impl true
  # def update(assigns, socket) do
  #   # socket =
  #   #   socket
  #   #   |> assign(
  #   #     height:
  #   #       (Enum.count(assigns.road.right) + Enum.count(assigns.road.left)) *
  #   #         (assigns.lane_width + 1)
  #   #   )
  #   #   |> assign(assigns)

  #   {:ok, socket}
  # end

  @impl true
  def render(assigns) do
    # <g width={@road.length * 100} height={@height}>
    ~F"""
    {!--
    <g width={60} height={60}>
    --}
    <circle cx={@junction.x} cy={@junction.y} r="8" fill="#869d9d" />
    {!--
    </g>
    --}
    """
  end
end
