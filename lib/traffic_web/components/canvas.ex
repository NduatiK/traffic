defmodule TrafficWeb.Components.Canvas do
  use Surface.LiveComponent

  prop width, :integer
  prop height, :integer
  prop padding, :integer

  slot default
  slot overlays
  alias TrafficWeb.Components.Vehicle.Helpers, as: Vehicles

  @impl true
  def render(assigns) do
    # width={@width + @padding * 2}
    ~F"""
    <div class="w-screen h-screen bg-darkness-300">
      <div class="fixed z-10 top-0 right-0 left-0 bottom-0 pointer-events-none click-through-parent canvas">
        <#slot name="overlays" />
      </div>
      <svg
        x="0px"
        y="0px"
        class="w-screen h-screen fixed top-0 right-0 left-0 bottom-0"
        viewBox={"#{-@padding} #{-@padding} #{@width + @padding} #{@height + @padding}"}
        xml:space="preserve"
      >
        <defs>
          {{:safe, Vehicles.Mustang.svg()}} {{:safe, Vehicles.Bus.svg()}}
        </defs>
        <#slot />
      </svg>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end
end
