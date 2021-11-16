defmodule TrafficWeb.Components.Logo do
  use Surface.Component

  @impl true
  def render(assigns) do
    ~F"""
    <span class="m-3 text-lime-500 font-serif tracking-wide font-bold text-xl">Traffique</span>
    """
  end
end
