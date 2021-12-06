defmodule TrafficWeb.Components.Button do
  use Surface.Component

  @doc """
  The button type, defaults to "button", mainly used for instances like modal X to close style buttons
  where you don't want to set a type at all. Setting to nil makes button have no type.
  """
  prop(type, :string, default: "button")

  @doc "The label of the button, when no content (default slot) is provided"
  prop(label, :string)

  @doc "The aria label for the button"
  prop(aria_label, :string)

  @doc "The color of the button"
  prop(color, :string, values: ~w(primary secondary link info success warning danger))

  @doc "The value for the button"
  prop(value, :string)
  @doc "phx_disable_with"
  prop(disable_with, :string)

  @doc "Button is expanded (full-width)"
  prop(expand, :boolean)

  @doc "Set the button as disabled preventing the user from interacting with the control"
  prop(disabled, :boolean)

  @doc "Outlined style"
  prop(outlined, :boolean)
  prop(padding_y, :integer, default: 3)
  prop(padding_x, :integer, default: 4)

  @doc "Rounded style"
  prop(rounded, :boolean)

  @doc "Hovered style"
  prop(hovered, :boolean)

  @doc "Focused style"
  prop(focused, :boolean)

  @doc "Active style"
  prop(active, :boolean)

  @doc "Selected style"
  prop(selected, :boolean)

  @doc "Loading state"
  prop(loading, :boolean)

  @doc "plain style"
  prop(plain, :boolean)

  @doc "destructive style"
  prop(destructive, :boolean)
  prop(cta, :boolean)

  @doc "Triggered on click"
  prop(click, :event)
  prop(confirm, :string)

  @doc "Css classes to propagate down to button. Default class if no class supplied is simply _button_"
  prop(class, :css_class, default: [])

  @doc """
  The content of the generated `<button>` element. If no content is provided,
  the value of property `label` is used instead.
  """
  slot(default)

  defp base_style() do
    classes = [
      "font-bold",
      "cursor-pointer",
      "text-sm",
      "rounded-md",
      "group",
      "hover:bg-opacity-60",
      "focus:outline-none",
      "focus:ring-0",
      "transition-colors"
    ]

    Enum.join(classes, " ")
  end

  def render(assigns) do
    ~F"""
    <button
      type={@type}
      aria-label={@aria_label}
      :on-click={@click}
      phx_disable_with={@disable_with}
      value={@value}
      disabled={@disabled}
      data-confirm={@confirm}
      class={[
        base_style(),
        "py-#{@padding_y}",
        "px-#{@padding_x}",
        "bg-primary-500": @color == "primary",
        "bg-rose-500": @color == "danger",
        "bg-gray-600": @color == "secondary",
        "w-full": @expand,
        "cursor-not-allowed opacity-50": @disabled
      ] ++
        render_one(
          plain: @plain,
          destructive: @destructive,
          cta: @cta
        ) ++
        @class}
    >
      <#slot>{@label}</#slot>
    </button>
    """
  end

  def render_style(:plain) do
    [
      "mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0  sm:w-auto sm:text-sm"
    ]
  end

  def render_style(:destructive) do
    [
      "w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:w-auto sm:text-sm"
    ]
  end

  def render_style(:cta) do
    [
      "cta w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:w-auto sm:text-sm"
    ]
  end

  def render_style(_) do
    false
  end

  def render_one(style_pairs) do
    style_pairs
    |> Enum.find_value([], fn
      {style, true} ->
        render_style(style)

      _ ->
        false
    end)
  end
end
