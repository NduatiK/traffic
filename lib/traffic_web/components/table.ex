defmodule TrafficWeb.Components.Table do
  @moduledoc """
  A simple HTML table.
  You can create a table by setting a souce `data` to it and defining
  columns using the `Table.Column` component.
  ```
  ~F\"\"\"
  <Table
    data={album <- [
      %{name: "The Dark Side of the Moon", artist: "Pink Floyd", released: "March 1, 1973"},
      %{name: "OK Computer", artist: "Radiohead", released: "June 16, 1997", selected: true},
      %{name: "Disraeli Gears", artist: "Cream", released: "November 2, 1967"},
      %{name: "Physical Graffiti", artist: "Led Zeppelin", released: "February 24, 1975"}
    ]}
    bordered
    expanded
  >
    <Column label="Album">
      {album.name}
    </Column>
    <Column label="Released">
      {album.released}
    </Column>
    <Column label="Artist">
      <a href="#">{album.artist}</a>
    </Column>
  </Table>
  \"\"\"
  
  ```
  """

  use Surface.Component
  @doc "The data that populates the table"
  prop(data, :list, required: true)

  @doc "The table is expanded (full-width)"
  prop(expanded, :boolean, default: true)

  @doc "Add borders to all the cells"
  prop(bordered, :boolean, default: false)

  @doc "Add stripes to the table"
  prop(striped, :boolean, default: false)

  @doc "The CSS class for the wrapping `<div>` element"
  prop(class, :css_class)
  prop(paginated, :boolean, default: false)

  @doc """
  A function that returns a class for the item's underlying `<tr>`
  element. The function receives the item and index related to
  the row.
  """
  prop(row_class, :fun)
  prop(col_class, :fun)

  slot(title)
  slot(cols, args: [item: ^data], required: true)
  @doc "The columns of the table"

  prop(page_number, :integer, default: 0)
  prop(total_pages, :integer, default: 1)
  prop(on_set_page, :event)

  defmodule Row do
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
        "flex space-x-#{@spacing}",
        "w-full": not @shrink,
        "items-#{@align}": @align,
        "justify-#{@distribute}": @distribute
      }>
        <#slot />
      </div>
      """
    end
  end

  def render(assigns) do
    ~F"""
    <div class={@class}>
      <Row align="center" distribute="between" class={"pt-1" <> if @paginated, do: " pb-1", else: ""}>
        <div>
          <slot name="title" />
        </div>
        <nav class="flex items-center" :if={@paginated}>
          <span
            :on-click={@on_set_page}
            phx-value-page={@page_number - 1}
            class={
              "w-full p-4 border border-r-transparent text-base rounded-l-xl text-gray-600 bg-white hover:bg-gray-100",
              "pointer-events-none": @page_number == 0
            }
          >
            <svg width="9" fill="currentColor" height="8" class="" viewBox="0 0 1792 1792" xmlns="http://www.w3.org/2000/svg">
              <path d="M1427 301l-531 531 531 531q19 19 19 45t-19 45l-166 166q-19 19-45 19t-45-19l-742-742q-19-19-19-45t19-45l742-742q19-19 45-19t45 19l166 166q19 19 19 45t-19 45z"> </path>
            </svg>
          </span>
          {#for idx <- Enum.to_list(1..@total_pages)}
            <span
              :on-click={@on_set_page}
              phx-value-page={idx - 1}
              class={
                "w-full px-4 py-2 border border-l-0 text-base  bg-white hover:bg-gray-100 ",
                "border-l-2": @total_pages == 1,
                "pointer-events-none": current_page?(@page_number, idx),
                "border-violet-400 border-l-2 text-violet-500 border-2": current_page?(@page_number, idx)
              }
            >{idx}</span>
          {/for}
          <span
            :on-click={@on_set_page}
            phx-value-page={@page_number + 1}
            class={
              "w-full p-4 border-t border-b border-r text-base rounded-r-xl text-gray-600 bg-white hover:bg-gray-100",
              "pointer-events-none": @total_pages == @page_number + 1
            }
          >
            <svg width="9" fill="currentColor" height="8" class="" viewBox="0 0 1792 1792" xmlns="http://www.w3.org/2000/svg">
              <path d="M1363 877l-742 742q-19 19-45 19t-45-19l-166-166q-19-19-19-45t19-45l531-531-531-531q-19-19-19-45t19-45l166-166q19-19 45-19t45 19l742 742q19 19 19 45t-19 45z"> </path>
            </svg>
          </span>
        </nav>
      </Row>
      <div class={
        "container flex flex-col mt-1 w-full  bg-white dark:bg-gray-800 sm:rounded-lg shadow-md border border-gray-300",
        @class,
        "border shadow-md border-gray-300": @bordered
      }>
        <table class={
          "min-w-full",
          "w-full": @expanded,
          "divide-y divide-gray-300": @bordered,
          "is-striped": @striped
        }>
          <thead style="overflow: clip" class="sm:rounded-t-lg">
            <tr>
              <th
                :for={col <- @cols}
                scope="col"
                class={
                  col[:class] || "",
                  "bg-gray-50 px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider",
                  col_class_fun(@col_class).(-1)
                }
              >
                {col.label}
              </th>
            </tr>
          </thead>
          <tbody class="sm:rounded-lg divide-y divide-gray-200">
            <tr :for={{item, index} <- Enum.with_index(@data)} class={row_class_fun(@row_class).(item, index)}>
              <td :for.index={index <- @cols} class={"px-3 py-2 ", col_class_fun(@col_class).(index)}>
                <div class="inline-block"><#slot name="cols" index={index} :args={item: item} /></div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp row_class_fun(nil), do: fn _, _ -> "" end
  defp row_class_fun(row_class), do: row_class
  defp col_class_fun(nil), do: fn _ -> "" end
  defp col_class_fun(col_class), do: col_class

  def current_page?(page_number, idx) do
    page_number == idx - 1
  end

  def first_page?(page_number) do
    page_number <= 1
  end

  defmodule Column do
    @moduledoc """
    Defines a column for the parent table component.
    The column instance is automatically added to the table's
    `cols` slot.
    """

    use Surface.Component, slot: "cols"

    @doc "Column header text"
    prop(label, :string, required: true)
    prop(class, :css_class)
  end
end
