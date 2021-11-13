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
      {Traffic.Network.Server, []},
      {
        Desktop.Window,
        [
          app: @app,
          id: TrafficWindow,
          title: "Traffique",
          size: {600, 500},
          icon: "icon.png",
          # menubar: TodoApp.MenuBar,
          # icon_menu: TodoApp.Menu,
          url: &TrafficWeb.Endpoint.url/0
        ]
      }

      # Start a worker by calling: Traffic.Worker.start_link(arg)
      # {Traffic.Worker, arg}
    ]

    Desktop.identify_default_locale(TrafficWeb.Gettext)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Traffic.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrafficWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
