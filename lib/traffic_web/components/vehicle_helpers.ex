defmodule TrafficWeb.Components.Vehicle.Helpers do
  defmodule Mustang do
    use Surface.Component
    prop(breadth, :integer, default: 30)
    prop(length, :integer, default: 30)
    prop(color, :string)

    mustang_path = Path.join(__DIR__, "./muscle_car.svg")

    @mustang_svg File.read!(mustang_path)

    def svg() do
      @mustang_svg
    end

    def render(assigns) do
      ~F"""
        <svg width={@length} height={@breadth} viewBox="0 0 959 452" style={"color: #{@color}"}>
          <use xlink:href="#mustang" />
        </svg>
      """
    end
  end

  defmodule Bus do
    use Surface.Component
    prop(breadth, :integer, default: 30)
    prop(length, :integer, default: 30)
    # prop(breadth, :integer, default: 50)
    # prop(length, :integer, default: 80)

    prop(color, :string)

    bus_path = Path.join(__DIR__, "./bus.svg")

    @bus_svg File.read!(bus_path)

    def svg() do
      @bus_svg
    end

    def render(assigns) do
      ~F"""
        <svg width={@length} height={@breadth} viewBox="0 0 2889 771" style={"color: #{@color}"}>
          <use xlink:href="#bus" />
        </svg>
      """
    end
  end
end
