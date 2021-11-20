defmodule TrafficWeb.Components.Lofi.Vehicle do
  use Surface.Component
  prop(class, :string, default: "items-center")
  prop(flip, :boolean, default: false)
  prop(color, :string, default: "blue")
  prop(x, :integer, default: 0)
  prop(y, :integer, default: 0)
  prop(breadth, :integer, default: 30)
  prop(length, :integer, default: 30)
  prop(vehicle, :map)

  def render(assigns) do
    ~F"""
    <circle
      cx={round(@x)}
      cy={round(@y)}
      r={3}
      stroke={render_speed(@vehicle)}
      stroke-width={2}
      fill={render_speed(@vehicle)}
    />
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
