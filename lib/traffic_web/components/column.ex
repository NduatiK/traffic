defmodule TrafficWeb.Components.Column do
  use Surface.Component

  prop(spacing, :integer)
  prop(class, :css_class)
  prop(shrink, :boolean, default: false)
  prop(align, :string)
  prop(distribute, :string)

  slot(default)

  def render(assigns) do
    ~F"""
    <div class={
      "flex flex-col",
      @class,
      "space-y-#{@spacing}",
      "w-full": not @shrink,
      "items-#{@align}": @align,
      "justify-#{@distribute}": @distribute
    }>
      <#slot />
    </div>
    """
  end
end
