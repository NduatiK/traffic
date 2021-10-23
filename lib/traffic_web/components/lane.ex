defmodule TrafficWeb.Components.Lane do
  use Surface.LiveComponent

  alias TrafficWeb.Components.Vehicle
  alias TrafficWeb.Components.Lane
  prop(class, :string, default: "items-center")
  prop(lanes, :list)
  prop(width, :integer)
  prop(lane_width, :integer)
  prop(road_length, :integer)
  prop(flip, :boolean, default: false)
  prop(offset, :integer, default: 0)

  slot(default)

  def lane_width, do: 30

  def render(assigns) do
    ~F"""
    <g transform-origin="center" transform={if @flip, do: "scale(-1, 1)"}>
      {#for {vehicles, index} <- Enum.with_index(@lanes)}
        {#for {vehicle, position} <- vehicles}
          <Vehicle id={vehicle.id} flip={@flip} x={position / @road_length * @width} y={@lane_width * index - 1 + @offset} color="orange" />
        {/for}
        {#if index + 1 != @lanes |> Enum.count()}
          {!-- Draw divider if not last lane --}
          <line
            x1="0"
            y1={(index + 1) * @lane_width + @offset}
            x2={@width}
            y2={(index + 1) * @lane_width + @offset}
            stroke="blue"
            stroke-width="1"
            stroke-dasharray="8 4"
          />
        {/if}
      {/for}
    </g>
    """
  end
end
