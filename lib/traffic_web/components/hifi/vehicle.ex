defmodule TrafficWeb.Components.Vehicle do
  use Surface.LiveComponent
  alias __MODULE__.Helpers.{Mustang, Bus}
  prop(class, :string, default: "items-center")
  prop(flip, :boolean, default: false)
  prop(color, :string, default: "blue")
  prop(x, :integer, default: 0)
  prop(y, :integer, default: 0)
  prop(breadth, :integer, default: 30)
  prop(length, :integer, default: 30)
  prop(vehicle, :map)

  # def render(assigns) do
  #   ~F"""
  #   <svg x={round(@x)} y={round(@y)}>
  #     <svg width={@length} height={@breadth} viewBox="0 0 30 10" style="color: orange">
  #       <use xlink:href="#mustang" />
  #     </svg>s
  #   </svg>
  #   """
  # end

  # def mustang() do
  #   """
  #   <rect x="0" y="0" width="30" height="10" fill="currentColor"  id="mustang"/>
  #   """
  # end

  def render(assigns) do
    ~F"""
    <svg x={round(@x)} y={round(@y)}>
      <Mustang breadth={@breadth} length={@length} color={render_speed(@vehicle)} />
    </svg>
    """
  end

  def render_speed(vehicle) do
    cond do
      vehicle.speed > 2 -> "gray"
      vehicle.speed > 1 -> "orange"
      true -> "green"
    end
  end
end
