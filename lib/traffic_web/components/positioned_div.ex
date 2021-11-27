defmodule TrafficWeb.Components.PositionedDiv do
  use Surface.Component

  prop(top, :integer, default: 12)
  prop(right, :integer, default: 12)

  slot default
  @impl true
  def render(assigns) do
    ~F"""
    <div class="absolute" style={top: "#{@top / 4}rem", right: "#{@right / 4}rem"}>
      <#slot />
    </div>
    """
  end
end
