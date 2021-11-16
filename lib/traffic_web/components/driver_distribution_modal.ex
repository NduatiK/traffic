defmodule TrafficWeb.Components.DriverDistributionModal do
  use Surface.Component

  prop(width, :integer)
  prop(height, :integer)
  prop(padding, :integer)
  prop(top, :integer, default: 12)
  prop(left, :integer, default: 12)
  prop(right, :integer, default: 12)
  prop(driver_distributions, :map)

  @impl true
  def render(assigns) do
    ~F"""
    <div
      style={top: "#{@top / 4}rem", right: "#{@right / 4}rem"}
      id="driver_dist_modal"
      x-data="{ open: false }"
      x-bind:class="{'rounded bg-transparent shadow': true, 'relative overflow-hidden w-10 h-10': !open}"
    >
      <div x-bind:class="{'rounded bg-white shadow p-2 absolute': true, 'top-0 right-0': open}">
        <div class="flex flex-row justify-between text-indigo-800">
          <svg @click="open = !open" xmlns="http://www.w3.org/2000/svg" width="24" height="24" style="fill:currentColor"><path d="m20.772 10.156-1.368-4.105A2.995 2.995 0 0 0 16.559 4H7.441a2.995 2.995 0 0 0-2.845 2.051l-1.368 4.105A2.003 2.003 0 0 0 2 12v5c0 .753.423 1.402 1.039 1.743-.013.066-.039.126-.039.195V21a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-2h12v2a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-2.062c0-.069-.026-.13-.039-.195A1.993 1.993 0 0 0 22 17v-5c0-.829-.508-1.541-1.228-1.844zM4 17v-5h16l.002 5H4zM7.441 6h9.117c.431 0 .813.274.949.684L18.613 10H5.387l1.105-3.316A1 1 0 0 1 7.441 6z" /><circle cx="6.5" cy="14.5" r="1.5" /><circle cx="17.5" cy="14.5" r="1.5" /></svg>
          <h2 @click="open = !open" class="font-bold leading-normal mt-0 mb-2">Driver Distributions</h2>
        </div>
        <div class="w-full p-2 bg-gray-200 rounded">
          <div class="flex flex-col justify-between h-full space-y-2 text-sm">
            {#for {name, value} <- @driver_distributions}
              <div class="flex flex-row space-x-2 items-center">
                <span class="w-16">{Atom.to_string(name) |> String.replace("_", " ")}</span>
                <input
                  id="slider_1"
                  value={value * 100}
                  phx-hook="PushEvent"
                  x-on:change={"pushEventHook.pushEvent_('slider_changed',{name: '#{name}', value: $event.target.value/100})"}
                  type="range"
                />
                <span>{value}</span>
              </div>
            {/for}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
