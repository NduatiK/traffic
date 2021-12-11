defmodule TrafficWeb.Components.PositionedButton do
  use Surface.Component

  prop(top, :integer, default: 12)
  prop(right, :integer, default: 12)
  prop click, :event

  slot default
  @impl true
  def render(assigns) do
    ~F"""
    <button
      class="rounded p-2 bg-white shadow absolute border"
      style={top: "#{@top / 4}rem", right: "#{@right / 4}rem"}
      :on-click={@click}
    >
      <#slot />
    </button>
    """
  end
end
