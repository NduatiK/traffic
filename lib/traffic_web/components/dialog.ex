defmodule TrafficWeb.Components.Dialog do
  use Surface.Component

  prop(title, :string, required: true)
  prop(ok_label, :string, default: "Ok")
  prop(close_label, :string, default: "Close")
  prop(ok_click, :event, default: "close")
  prop(close_click, :event, default: "close")

  slot(default, required: true)
  slot(footer)

  def render(assigns) do
    ~F"""
    <div
      class="fixed z-40 inset-0 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
      :on-window-keydown={@close_click}
      phx-key="Escape"
    >
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" /> {!-- :on-click={@close_click} --} {!--
        <!-- This element is to trick the browser into centering the modal contents. -->
          --} <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span> {!-- <!--
          Modal panel, show/hide based on modal state.
    
          Entering:
            From:
            To:
          Leaving:
            From:
            To:
        --> x-show="open_modal" --}
        <div
          class="inline-block relative align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full"
          x-cloak
          x-transition:enter="transition ease-out duration-300"
          x-transition:enter-start="transform opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          x-transition:enter-end="transform opacity-100 translate-y-0 sm:scale-100"
          x-transition:leave="transition ease-in duration-200"
          x-transition:leave-start="transform opacity-100 translate-y-0 sm:scale-100"
          x-transition:leave-end="transform opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
        >
          {!--  <button type="button"
    
        class="text-gray-400 bg-transparent top-2 right-4 hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center absolute"
        :on-click={@close_click}
        >
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>
          </button> --}
          <div class="bg-white px-4 pt-6 pb-4 sm:p-6 sm:pb-4">
            <#slot />
          </div>
          <div :if={slot_assigned?(:footer)} class="bg-gray-100 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <#slot name="footer" />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def example_buttons() do
    """
    # ~F\"""
    <button type="button" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
    Deactivate
    </button>
    <button type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
    Cancel
    </button>
    """
  end
end
