defmodule TrafficWeb.Components.PositionedButton do
  use Surface.Component

  prop(top, :integer, default: 12)
  prop(right, :integer, default: 12)
  prop click, :event

  slot default
  @impl true
  def render(assigns) do
    ~F"""
    <div
      class="rounded cursor-pointer bg-white shadow p-2 absolute"
      :on-click={@click}
      style={top: "#{@top / 4}rem", right: "#{@right / 4}rem"}
    >
      <#slot />
    </div>
    """
  end
end
