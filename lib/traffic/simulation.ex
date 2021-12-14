defmodule Traffic.SimulationListSupervisor do
  alias Traffic.SimulationRegistry
  use DynamicSupervisor
  alias Traffic.Network.SimulationSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_simulation(name, timing_strategy) do
    spec =
      {SimulationSupervisor,
       Keyword.put(
         [
           config: %Traffic.Network.Config{
             timing_strategy: timing_strategy
           }
         ],
         :name,
         name
       )}

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, spec)

    SimulationRegistry.add_simulation(
      {name,
       %{
         strategy: timing_strategy,
         via: SimulationSupervisor.via(name),
         wait_time: 0
       }}
    )
  end

  def stop_simulation(pid, name) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
    SimulationRegistry.remove_simulation(name)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
