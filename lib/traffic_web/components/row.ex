defmodule TrafficWeb.Components.Row do
  use Surface.Component

  prop(class, :css_class, default: "items-center")
  prop(spacing, :integer, default: 0)
  prop(shrink, :boolean, default: false)
  prop(align, :string)
  prop(distribute, :string)

  slot(default)

  def render(assigns) do
    ~F"""
    <div class={
      @class,
      "flex",
      "space-x-#{@spacing}",
      "w-full": not @shrink,
      "items-#{@align}": @align,
      "justify-#{@distribute}": @distribute
    }>
      <#slot />
    </div>
    """
  end
end
