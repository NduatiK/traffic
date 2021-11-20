defmodule TrafficWeb.Components.Lofi.Lane do
  use Surface.LiveComponent
  alias TrafficWeb.Components.Lofi.Vehicle

  prop(class, :string, default: "items-center")
  prop(road_name, :string)
  prop(lanes, :list)
  prop(light, :string)
  prop(width, :integer)
  prop(lane_width, :integer)
  prop(road_length, :integer)
  prop(flip, :boolean, default: false)
  prop(offset, :integer, default: 0)
  prop(direction, :string, default: "0")
  prop(show, :boolean, default: false)

  slot(default)

  def lane_width, do: 30

  def render(assigns) do
    # transform-origin={"#{@width / 2} 0"} transform={if @flip, do: "scale(-1, 1)"}
    ~F"""
    <g style={"transform-origin: #{@width / 2}px 0px; transform: #{if @flip, do: "scale(-1, 1)"} "}>
      {#for {vehicles, index} <- Enum.with_index(@lanes)}
        {#for {vehicle, position} <- vehicles}
          <Vehicle
            vehicle={vehicle}
            flip={@flip}
            x={position / @road_length * @width}
            y={3 + @offset + index * 2}
            color="orange"
          />
        {/for}
      {/for} <rect width={@width} height={10} fill="transparent" />
    </g>
    """
  end
end
