defmodule TrafficWeb.Components.Vehicle do
  use Surface.LiveComponent

  prop(class, :string, default: "items-center")
  prop(flip, :boolean, default: false)
  prop(color, :string, default: "blue")
  prop(x, :integer, default: 0)
  prop(y, :integer, default: 0)
  prop(height, :integer, default: 30)
  prop(width, :integer, default: 30)

  # def render(assigns) do
  #   ~F"""
  #   <svg x={round(@x)} y={round(@y)}>
  #     <svg width={@width} height={@height} viewBox="0 0 30 10" style="color: orange">
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
    <svg width={@width} height={@height} viewBox="0 0 959 452" style="color: orange">
        <use xlink:href="#mustang" />
      </svg>s
    </svg>
    """
  end

  mustang_path = Path.join(__DIR__, "./muscle_car.svg")

  @mustang_svg File.read!(mustang_path)

  def mustang() do
    @mustang_svg
  end
end
