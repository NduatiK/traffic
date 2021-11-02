defmodule TrafficWeb.Components.Lofi.Lane do
  use Surface.LiveComponent
  alias TrafficWeb.Components.Lofi.LaneDivider
  alias TrafficWeb.Components.Lofi.Vehicle
  alias TrafficWeb.Components.Lofi.Lane

  prop(class, :string, default: "items-center")
  prop(road_name, :string)
  prop(lanes, :list)
  prop(width, :integer)
  prop(lane_width, :integer)
  prop(road_length, :integer)
  prop(flip, :boolean, default: false)
  prop(offset, :integer, default: 0)
  prop(direction, :string, default: "0")

  slot(default)

  def lane_width, do: 30

  def render(assigns) do
    ~F"""
    <svg width={@width} transform-origin={"#{@width / 2} 0"} transform={if @flip, do: "scale(-1, 1)"}>
      {#for {vehicles, index} <- Enum.with_index(@lanes)}
        {#for {vehicle, position} <- vehicles}
          <Vehicle
            id={vehicle.id}
            vehicle={vehicle}
            flip={@flip}
            x={position / @road_length * @width}
            y={3 + @offset + index * 2}
            color="orange"
          />
        {/for}
      {/for}
    </svg>
    """
  end
end
