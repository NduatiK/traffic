defmodule TrafficWeb.Components.Lane do
  use Surface.LiveComponent
  alias TrafficWeb.Components.LaneDivider
  alias TrafficWeb.Components.Vehicle
  alias TrafficWeb.Components.Lane

  prop(class, :string, default: "items-center")
  prop(lanes, :list)
  prop(width, :integer)
  prop(lane_width, :integer)
  prop(road_length, :integer)
  prop(flip, :boolean, default: false)
  prop(offset, :integer, default: 0)
  prop(direction, :string, default: 0)

  slot(default)

  def lane_width, do: 30

  def render(assigns) do
    ~F"""
    <svg width={@width} transform-origin={"#{@width / 2} 0"} transform={if @flip, do: "scale(-1, 1)"}>
      {#for {vehicles, index} <- Enum.with_index(@lanes)}
        {#if index + 1 != @lanes |> Enum.count()}
          <LaneDivider
            id={Integer.to_string(index) <> @direction}
            width={@width}
            index={index}
            lane_width={@lane_width}
            offset={@offset}
          />
        {/if} {#for {vehicle, position} <- vehicles}
          <Vehicle
            id={vehicle.id}
            vehicle={vehicle}
            flip={@flip}
            x={position / @road_length * @width}
            y={@lane_width * index - 1 + @offset}
            color="orange"
          />
        {/for}
      {/for}
    </svg>
    """
  end
end
