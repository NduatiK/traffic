defmodule TrafficWeb.Components.LineGraphModal do
  use Surface.Component

  prop(width, :integer)
  prop(height, :integer)
  prop(padding, :integer)
  prop(top, :integer, default: 12)
  prop(left, :integer, default: 12)
  prop(right, :integer, default: 12)

  @impl true
  def render(assigns) do
    ~F"""
    <div
      style={top: "#{@top / 4}rem", right: "#{@right / 4}rem"}
      id="driver_dist_modal"
      x-data="{ open: true }"
      x-bind:class="{'rounded bg-transparent': true, 'relative overflow-hidden w-10 h-10 shadow': !open, 'shadow-lg': open}"
    >
      <div
       x-bind:class="{'rounded bg-white  p-2 absolute': true,'shadow': !open, 'border shadow-lg top-0 right-0': open}"
       x-bind:style="{'width: 24rem': open}"

      >
        <div class="flex flex-row justify-between text-indigo-800">
          <span @click="open = !open">🚦</span>
          <h2 @click="open = !open" class="font-bold leading-normal mt-0 mb-2">Average Wait Time</h2>
        </div>
        <div class="w-full p-2 ">
          <div style="max-height: 600px; height: 300px">
            <canvas id="chart-canvas" style="max-height: 600px; height: 300px" phx-update="ignore" phx-hook="CustomLineChart" />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
