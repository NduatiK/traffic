defmodule TrafficWeb.Components.LookAheadModal do
  use Surface.Component

  prop(width, :integer)
  prop(height, :integer)
  prop(padding, :integer)
  prop(top, :integer, default: 12)
  prop(left, :integer, default: 12)
  prop(right, :integer, default: 12)
  prop(look_ahead, :map)
  # typedstruct module: Vision do
  #   field(:junction_light, atom(), default: nil)
  #   field(:junction_distance, integer(), default: nil)
  #   field(:appx_distance_to_lead, integer(), default: nil)
  #   field(:appx_speed_of_lead, integer(), default: nil)
  #   field(:appx_speed_of_pack, integer(), default: nil)
  # end

  @impl true
  def render(assigns) do
    ~F"""
    <div
      style={top: "#{@top / 4}rem", right: "#{@right / 4}rem;"}
      id="look_ahead_modal"
      x-data="{ open: true }"
      x-bind:class="{'rounded bg-transparent shadow border': true, 'relative overflow-hidden w-10 h-10': !open, 'z-10': open}"
    >
      <div x-bind:class="{'rounded bg-white shadow p-2 absolute': true, 'top-0 right-0': open}">
        <div class="flex flex-row justify-between text-indigo-800">
          <svg
            @click="open = !open"
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            style="fill: rgba(0, 0, 0, 1)"
          ><path d="M20 17V7c0-2.168-3.663-4-8-4S4 4.832 4 7v10c0 2.168 3.663 4 8 4s8-1.832 8-4zM12 5c3.691 0 5.931 1.507 6 1.994C17.931 7.493 15.691 9 12 9S6.069 7.493 6 7.006C6.069 6.507 8.309 5 12 5zM6 9.607C7.479 10.454 9.637 11 12 11s4.521-.546 6-1.393v2.387c-.069.499-2.309 2.006-6 2.006s-5.931-1.507-6-2V9.607zM6 17v-2.393C7.479 15.454 9.637 16 12 16s4.521-.546 6-1.393v2.387c-.069.499-2.309 2.006-6 2.006s-5.931-1.507-6-2z" /></svg>
          <h2 @click="open = !open" class="font-bold leading-normal mt-0 mb-2">Vehicle Vision</h2>
        </div>
        <div class="w-48  p-2 bg-gray-200 rounded">
          <div class="flex flex-col justify-between h-12 space-y-2 text-sm">
            <svg
              width={170}
              height={80}
              xml:space="preserve"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
            >
              <rect width={10} height={5} x={0} y={25} fill="blue" />
              <rect :if={@look_ahead.appx_distance_to_lead} x={(@look_ahead.appx_distance_to_lead || 0) / 40 * 150} y={25}  width={10} height={5} fill="green" />
              <text :if={@look_ahead.appx_distance_to_lead} x={(@look_ahead.appx_distance_to_lead || 0) / 40 * 150} y="45" class="text-sm">{(@look_ahead.appx_distance_to_lead || 0)}m</text>
              <circle
                :if={@look_ahead.junction_distance}
                r={5}
                cx={(@look_ahead.junction_distance || 0) / 40 * 150 + 10}
                cy={27}
                fill={"#{@look_ahead.junction_light}"}
                stroke="black"
              />
              <text :if={@look_ahead.junction_distance} x={(@look_ahead.junction_distance || 0) / 40 * 150} y="20" class="text-sm">{@look_ahead.junction_distance}m</text>
            </svg>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
