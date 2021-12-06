defmodule TrafficWeb.Pages.HomePage do
  use TrafficWeb, :surface_view_helpers

  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias TrafficWeb.Components.Button
  alias TrafficWeb.Components.Dialog
  alias TrafficWeb.Components.Row
  alias TrafficWeb.Components.Table
  alias TrafficWeb.Components.Table.Column
  alias TrafficWeb.Pages.LofiMap

  data processes, :list, default: []
  data show_modal, :boolean, default: true
  data changeset, :map

  defmodule FormData do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field(:strategy, Ecto.Enum, values: Traffic.Network.Timing.Strategy.all())
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:name, :strategy])
      |> validate_required([:name, :strategy])
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = FormData.changeset(%FormData{}, %{})

    socket
    |> schedule_list_update(0)
    |> assign(changeset: changeset)
    |> then(&{:ok, &1, temporary_assigns: [processes: []]})
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Form :if={@show_modal} change="validate" submit="save" for={@changeset}>
      <Dialog title="User form" close_click="close_modal">
        <!--
        <div class="flex flex-col space-y-4">
          <span>Do you want to an invite to your members?</span> <span class="text-sm">Emails will only be sent to those you have not invited yet</span>
        </div>
        -->
        <Field name={:name}>
          <Label class="block text-sm font-medium text-gray-700 mb-1" text="Simulation Name" />
          <TextInput class="styled-input" opts={required: true, placeholder: ""} /> <ErrorTag />
        </Field>

        <Field name={:strategy} class="mt-2">
          <Label class="block text-sm font-medium text-gray-700 mb-1" text="Strategy" />
          <Select class="styled-input" options={Ecto.Enum.values(FormData, :strategy)} opts={required: true} /> <ErrorTag />
        </Field>
        <:footer>
          <Row spacing={2} distribute="end">
            <Button type="submit" cta label="Create" click="start_simulation" />
            <Button type="button" plain label="Cancel" click="close_modal" />
          </Row>
        </:footer>
      </Dialog>
    </Form>
    <div class="p-4 md:p-12">
      <h1 class="mb-4 text-xl">Traffique</h1>
      <Table data={{name, process_info} <- @processes} bordered expanded>
        <Column label="Simulations">
          {name}
        </Column>
        <Column label="Strategy">
          {strategy_name(process_info.strategy)}
        </Column>
        <Column label="">
          <Link class="text-sm text-blue-500" to={Routes.live_path(@socket, LofiMap, name)}>
            VIEW
          </Link>
        </Column>
      </Table>
      <button
        class="mt-4 bg-blue-400 bg-opacity-50 hover:bg-opacity-75 transition-colors duration-200 rounded font-semibold py-2 px-4 inline-flex"
        :on-click="open_modal"
      >
        Create Simulation
      </button>
    </div>
    """
  end

  @impl true
  def handle_params(_params, url, socket) do
    %URI{path: path} = URI.parse(url)

    socket
    |> assign(path: path)
    |> then(&{:noreply, &1})
  end

  def schedule_list_update(socket, delay \\ 1000) do
    Process.send_after(self(), :update_list, delay)
    socket
  end

  @impl true
  def handle_event("open_modal", _, socket) do
    socket
    |> assign(show_modal: true)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("start_simulation", _, socket) do
    socket
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    socket
    |> assign(show_modal: false)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("validate", %{"form_data" => params}, socket) do
    changeset =
      %FormData{}
      |> FormData.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"form_data" => params}, socket) do
    changeset =
      %FormData{}
      |> FormData.changeset(params)

    if changeset.valid? do
      strategy = Ecto.Changeset.get_field(changeset, :strategy)
      name = Ecto.Changeset.get_field(changeset, :name)

      Traffic.Simulation.start_simulation(:"#{name}", strategy)

      socket
      |> schedule_list_update(0)
      |> assign(changeset: FormData.changeset(%FormData{}, %{}), show_modal: false)
      |> then(&{:noreply, &1})
    else
      socket
      |> assign(changeset: changeset)
      |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_info(:update_list, socket) do
    socket
    |> schedule_list_update()
    |> assign(processes: Traffic.SimulationList.get_list())
    |> then(&{:noreply, &1})
  end

  def strategy_name(atom) do
    atom
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.reverse()
    |> hd()
  end
end
