defmodule TrafficWeb.Pages.LofiMap do
  alias TrafficWeb.Pages.HomePage
  use TrafficWeb, :surface_view_helpers
  alias Traffic.Network.Manager
  alias Traffic.Vehicles.VehicleServer
  alias Traffic.Statistics
  alias TrafficWeb.Components.Canvas
  alias TrafficWeb.Components.DriverDistributionModal
  alias TrafficWeb.Components.Lofi.RoadNetwork
  alias TrafficWeb.Components.Lofi.Road
  alias TrafficWeb.Components.LookAheadModal
  alias TrafficWeb.Components.PositionedButton
  alias TrafficWeb.Components.PositionedDiv
  alias TrafficWeb.Components.LineGraphModal

  data(width, :integer, default: 2000)
  data(height, :integer, default: 1010)
  data(padding, :integer, default: 50)
  data(graph, :map)
  data(paused, :boolean, default: false)
  data(network_id, :atom)
  data(average_speed, :integer, default: 0)
  data(averages, :any, default: :queue.from_list(List.duplicate(0, 30)))

  data(show_driver_distributions, :boolean, default: true)

  data(look_ahead, :map, default: nil)

  data(driver_distributions, :list, default: [])

  @impl true
  def mount(params, _session, socket) do
    Process.send_after(self(), :update_average, 2000)

    case validate_network_id(socket, params) do
      :error ->
        socket
        |> redirect(to: Routes.live_path(socket, HomePage))
        |> put_flash(:error, "The simulation #{params["id"]} does not exist")
        |> then(&{:ok, &1})

      {network_id, socket} ->
        socket
        |> assign(graph: Manager.get_graph(network_id))
        |> assign(
          driver_distributions:
            network_id
            |> Manager.get_driver_config()
            |> Map.to_list()
        )
        |> assign(paused: Manager.get_pause_status(network_id))
        |> then(&{:ok, &1})
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Canvas id="canvas" width={@width} height={@height} padding={@padding}>
      <:overlays>
        <PositionedButton right={6} top={6} click="reset_network">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1)">
            <path d="M10 11H7.101l.001-.009a4.956 4.956 0 0 1 .752-1.787 5.054 5.054 0 0 1 2.2-1.811c.302-.128.617-.226.938-.291a5.078 5.078 0 0 1 2.018 0 4.978 4.978 0 0 1 2.525 1.361l1.416-1.412a7.036 7.036 0 0 0-2.224-1.501 6.921 6.921 0 0 0-1.315-.408 7.079 7.079 0 0 0-2.819 0 6.94 6.94 0 0 0-1.316.409 7.04 7.04 0 0 0-3.08 2.534 6.978 6.978 0 0 0-1.054 2.505c-.028.135-.043.273-.063.41H2l4 4 4-4zm4 2h2.899l-.001.008a4.976 4.976 0 0 1-2.103 3.138 4.943 4.943 0 0 1-1.787.752 5.073 5.073 0 0 1-2.017 0 4.956 4.956 0 0 1-1.787-.752 5.072 5.072 0 0 1-.74-.61L7.05 16.95a7.032 7.032 0 0 0 2.225 1.5c.424.18.867.317 1.315.408a7.07 7.07 0 0 0 2.818 0 7.031 7.031 0 0 0 4.395-2.945 6.974 6.974 0 0 0 1.053-2.503c.027-.135.043-.273.063-.41H22l-4-4-4 4z" />
          </svg>
        </PositionedButton>
        <PositionedButton right={6} top={30} click="pause_network">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" style="fill: rgba(0, 0, 0, 1)">
            {#if @paused}
              <path d="M7 6v12l10-6z" />
            {#else}
              <path d="M8 7h3v10H8zm5 0h3v10h-3z" />
            {/if}
          </svg>
        </PositionedButton>
        <DriverDistributionModal
          top={18}
          right={6}
          :if={@show_driver_distributions}
          driver_distributions={@driver_distributions}
        />

        <LookAheadModal top={44} right={6} :if={@look_ahead} look_ahead={@look_ahead} />
        <LineGraphModal top={58} right={6} :if={@show_driver_distributions} />
        <PositionedDiv top={6} right={32}>
          <span>
            {@average_speed}
          </span>
        </PositionedDiv>
      </:overlays>
      <RoadNetwork id="network" network_id={@network_id} network={@graph} />
    </Canvas>
    """
  end

  @impl true
  def handle_params(_params, url, socket) do
    %URI{path: path} = URI.parse(url)

    socket
    |> assign(path: path)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({Traffic.Network.JunctionServer, state}, socket) do
    send_update(Junction,
      id: "junction_#{inspect(state.pid)}",
      color: state.color,
      junction: state.pid
    )

    socket
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({Traffic.Network.RoadServer, state}, socket) do
    send_update(Road,
      id: "road_#{inspect(state.pid)}"
    )

    socket
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(:update_average, socket) do
    Process.send_after(self(), :update_average, 1000)
    network_id = socket.assigns.network_id

    average_speed = Statistics.get_average_wait_time(network_id)

    averages =
      average_speed
      |> :queue.in(socket.assigns.averages)
      |> :queue.drop()

    socket
    |> push_event(
      "new-point",
      %{label: "Average Speed", value: average_speed}
    )
    |> assign(:average_speed, average_speed)
    |> assign(:averages, averages)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reset_network", _, socket) do
    Manager.reset_network(socket.assigns.network_id)

    socket
    |> redirect(to: socket.assigns.path)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("pause_network", _, socket) do
    network_id = socket.assigns.network_id
    IO.inspect("pausing")
    Manager.pause(network_id)
    IO.inspect("paused")

    socket
    |> assign(:paused, Manager.get_pause_status(network_id))
    |> then(&{:noreply, &1})
  end

  require IEx.Helpers
  @impl true
  def handle_event("focus-on-vehicle", params, socket) do
    look_ahead =
      params
      |> Map.get("vehicle")
      |> String.replace("#PID<", "")
      |> String.replace(">", "")
      |> IEx.Helpers.pid()
      |> VehicleServer.get_vision()

    socket
    |> assign(look_ahead: look_ahead)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("slider_changed", %{"name" => name, "value" => newValue}, socket)
      when is_number(newValue) and newValue >= 0 and newValue <= 1 do
    driver_distributions =
      socket.assigns.driver_distributions
      |> Enum.map(fn {k, v} ->
        if name == Atom.to_string(k) do
          {k, newValue}
        else
          {k, v}
        end
      end)
      |> Enum.into(%{})

    Manager.set_driver_config(socket.assigns.network_id, driver_distributions)

    socket
    |> assign(driver_distributions: driver_distributions)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reset_profiles", _, socket) do
    driver_distributions =
      socket.assigns.driver_distributions
      |> Enum.map(fn {k, _} ->
        {k, 0.5}
      end)
      |> Enum.into(%{})

    Manager.set_driver_config(socket.assigns.network_id, driver_distributions)

    socket
    |> assign(driver_distributions: driver_distributions)
    |> then(&{:noreply, &1})
  end

  def validate_network_id(socket, params) do
    try do
      network_id = String.to_existing_atom(params["id"])
      pid = GenServer.whereis(Traffic.Network.SimulationSupervisor.via(network_id))

      if is_pid(pid) do
        {network_id, assign(socket, network_id: network_id)}
      else
        :error
      end
    rescue
      _ ->
        :error
    end
  end
end
