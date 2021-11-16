defmodule TrafficWeb.Pages.LofiMap do
  use TrafficWeb, :surface_view_helpers
  alias TrafficWeb.Components.Lofi.{Road, RoadNetwork, Junction}
  alias TrafficWeb.Components.Canvas
  alias TrafficWeb.Components.{DriverDistributionModal, PositionedButton, Logo}

  data width, :integer, default: 2000
  data height, :integer, default: 1010
  data padding, :integer, default: 50
  data graph, :map

  data show_driver_distributions, :boolean, default: true
  data driver_distributions, :map, default: %{}

  @rate round(1000 / 24)
  # @rate round(1000 / 24)
  # @rate round(48000 / 24)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, @rate)

    socket =
      socket
      |> assign(graph: Traffic.Network.Server.get_graph(Traffic.Network.Server))
      |> assign(
        driver_distributions:
          Traffic.Network.Server.get_driver_config(Traffic.Network.Server)
          |> Map.to_list()
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(a, url, socket) do
    %URI{
      path: path
    } = URI.parse(url)

    socket =
      socket
      |> assign(path: path)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @rate)

    send_update(RoadNetwork, id: "network")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Canvas id="canvas" width={@width} height={@height} padding={@padding}>
      <:overlays>
      <Logo />
      <PositionedButton right={6} top={6}>
      <svg
      :on-click="reset_network"
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      style="fill: rgba(0, 0, 0, 1)"
      >
      <path d="M10 11H7.101l.001-.009a4.956 4.956 0 0 1 .752-1.787 5.054 5.054 0 0 1 2.2-1.811c.302-.128.617-.226.938-.291a5.078 5.078 0 0 1 2.018 0 4.978 4.978 0 0 1 2.525 1.361l1.416-1.412a7.036 7.036 0 0 0-2.224-1.501 6.921 6.921 0 0 0-1.315-.408 7.079 7.079 0 0 0-2.819 0 6.94 6.94 0 0 0-1.316.409 7.04 7.04 0 0 0-3.08 2.534 6.978 6.978 0 0 0-1.054 2.505c-.028.135-.043.273-.063.41H2l4 4 4-4zm4 2h2.899l-.001.008a4.976 4.976 0 0 1-2.103 3.138 4.943 4.943 0 0 1-1.787.752 5.073 5.073 0 0 1-2.017 0 4.956 4.956 0 0 1-1.787-.752 5.072 5.072 0 0 1-.74-.61L7.05 16.95a7.032 7.032 0 0 0 2.225 1.5c.424.18.867.317 1.315.408a7.07 7.07 0 0 0 2.818 0 7.031 7.031 0 0 0 4.395-2.945 6.974 6.974 0 0 0 1.053-2.503c.027-.135.043-.273.063-.41H22l-4-4-4 4z" />
      </svg>
      </PositionedButton>
        <DriverDistributionModal
          top={18}
          right={6}
          :if={@show_driver_distributions}
          driver_distributions={@driver_distributions}
        />
      </:overlays>
      <RoadNetwork id="network" network={@graph} />
    </Canvas>
    """
  end

  @impl true
  def handle_event("reset_network", _, socket) do
    Traffic.Network.Server.reset_network(Traffic.Network.Server)
    {:noreply, socket}
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

    Traffic.Network.Server.set_driver_config(Traffic.Network.Server, driver_distributions)

    {:noreply,
     socket
     |> assign(driver_distributions: driver_distributions)}
  end
end
