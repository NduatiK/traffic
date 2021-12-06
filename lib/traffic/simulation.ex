defmodule Traffic.Simulation do
  alias Traffic.SimulationList
  use DynamicSupervisor
  alias Traffic.Network.NetworkSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_simulation(name, timing_strategy) do
    spec =
      {NetworkSupervisor,
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

    SimulationList.add_simulation(
      {name,
       %{
         strategy: timing_strategy,
         via: NetworkSupervisor.via(name)
       }}
    )
  end

  def stop_simulation(pid, name) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
    SimulationList.remove_simulation(name)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
