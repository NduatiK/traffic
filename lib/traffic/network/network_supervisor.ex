defmodule Traffic.Network.NetworkSupervisor do
  use Supervisor
  alias Traffic.Network.Manager
  alias Traffic.Network.ChildSupervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg,
      name: Traffic.via_tuple(__MODULE__, Keyword.get(init_arg, :name))
    )
  end

  @impl true
  def init(init_arg) do
    children = [
      {Manager, init_arg},
      {ChildSupervisor, init_arg}
    ]

    Traffic.Statistics.start_up(Keyword.get(init_arg, :name))

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def via(name) do
    Traffic.via_tuple(__MODULE__, name)
  end

  def stop(name) do
    name
    |> via()
    |> Traffic.Simulation.stop_simulation(name)
  end
end
