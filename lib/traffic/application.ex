defmodule Traffic.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @app Mix.Project.config()[:app]

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Traffic.Repo,
      # Start the Telemetry supervisor
      TrafficWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Traffic.PubSub},
      # Start the Endpoint (http/https)
      TrafficWeb.Endpoint,
      # Start a network server
      {Traffic.Simulation, []},
      {Traffic.SimulationList, []},
      {Registry, keys: :unique, name: Registry.Traffic}
      # ,
      # {
      #   Desktop.Window,
      #   [
      #     app: @app,
      #     id: TrafficWindow,
      #     title: "Traffique",
      #     size: {600, 500},
      #     icon: "icon32x32.png",
      #     # menubar: TodoApp.MenuBar,
      #     # icon_menu: TodoApp.Menu,
      #     url: &TrafficWeb.Endpoint.url/0
      #   ]
      # }
    ]

    setup()

    opts = [strategy: :one_for_one, name: Traffic.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def setup() do
    # Desktop.identify_default_locale(TrafficWeb.Gettext)

    Task.async(fn ->
      :timer.sleep(1000)

      Traffic.Network.start_simulation_and_network(
        :NaiveStrategy,
        Traffic.Network.Timing.NaiveStrategy
      )

      Traffic.Network.start_simulation_and_network(
        :RandomizedNaiveStrategy,
        Traffic.Network.Timing.RandomizedNaiveStrategy
      )

      Traffic.Network.start_simulation_and_network(
        :SynchonizedStrategy,
        Traffic.Network.Timing.SynchonizedStrategy
      )

      Traffic.Network.start_simulation_and_network(
        :RandomizedSynchonizedStrategy,
        Traffic.Network.Timing.RandomizedSynchonizedStrategy
      )

      for i <- 0..10 do
        Traffic.Network.start_simulation_and_network(
          :"Genetic#{i}",
          Traffic.Network.Timing.GeneticEvolutionStrategy
        )
      end
    end)
  end

  # Tell Phoenix to update the endpoint configurationp
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrafficWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
