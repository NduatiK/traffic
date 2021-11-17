defmodule Traffic.Simulation do
  use DynamicSupervisor
  alias Traffic.Network.NetworkSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_simulation(name, opts) do
    spec = {NetworkSupervisor, Keyword.put(opts, :name, name)}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
