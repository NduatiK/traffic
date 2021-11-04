defmodule TrafficWeb.Pages.LofiMap do
  use TrafficWeb, :surface_view_helpers
  alias TrafficWeb.Components.Lofi.{Road, RoadNetwork, Junction}
  alias TrafficWeb.Components.Canvas
  alias TrafficWeb.Components.DriverDistributionModal

  data width, :integer, default: 2000
  data height, :integer, default: 1010
  data padding, :integer, default: 50
  data graph, :map

  data show_driver_distributions, :boolean, default: true
  data driver_distributions, :map, default: %{}

  @rate round(1000 / 24)
  # @rate round(48000 / 24)

  @impl true
  def mount(_params, session, socket) do
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

    # socket = assign(socket, :road, road)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Canvas id="canvas" width={@width} height={@height} padding={@padding}>
      <:overlays>
        <DriverDistributionModal id="driver_modal"

        top={6} right={6} :if={@show_driver_distributions}

        driver_distributions={@driver_distributions}/>
      </:overlays>
      <RoadNetwork id="network" network={@graph} />
    </Canvas>
    """
  end

  @impl true
  def handle_event("slider_changed", %{"name" => name, "value" => newValue} = params, socket)
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
