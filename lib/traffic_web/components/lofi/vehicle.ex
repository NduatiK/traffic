defmodule TrafficWeb.Components.Lofi.Vehicle do
  use Surface.Component
  prop(class, :string, default: "items-center")
  prop(flip, :boolean, default: false)
  prop(color, :string, default: "blue")
  prop(x, :integer, default: 0)
  prop(y, :integer, default: 0)
  prop(breadth, :integer, default: 30)
  prop(length, :integer, default: 30)
  prop(vehicle, :any)

  def render(assigns) do
    ~F"""
    <svg
      phx-value-vehicle={inspect(@vehicle.vehicle)}
      style="cursor:pointer"
      :on-click="focus-on-vehicle"
      version="1.1"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xmlns="http://www.w3.org/2000/svg"
      data[vehicle]="true"
    >
      <rect x={round(@x)} y={round(@y)} width={1} height={3} stroke="blue" stroke-width={2} fill="blue" />
    </svg>
    """
  end
end
