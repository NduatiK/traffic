defmodule Traffic.Network.Server do
  use GenServer
  alias Traffic.Network.{Road, Junction, Graph}
  alias Traffic.Network

  # Client
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def get_graph(pid) do
    GenServer.call(pid, :get_graph)
  end

  def get_compiled(pid) do
    GenServer.call(pid, :get_compiled)
  end

  def get_driver_config(pid) do
    GenServer.call(pid, :get_driver_config)
  end

  def set_driver_config(pid, config) do
    GenServer.cast(pid, {:set_driver_config, config})
  end

  def reset_network(pid) do
    GenServer.cast(pid, :reset_network)
  end

  # Server (callbacks)
  @impl true
  def init(_) do
    Process.send_after(self(), :tick, 5000)

    config = %Traffic.Network.Config{}

    {:ok,
     %{
       graph: Network.build_network(config),
       config:
         config
         |> IO.inspect()
     }}
  end

  @impl true
  def handle_call(:get_graph, _from, %{graph: network} = state) do
    {:reply, network, state}
  end

  @impl true
  def handle_call(:get_compiled, _from, %{graph: network} = state) do
    {junctions, roads} = Network.compile_network(network)

    {:reply, {junctions, roads}, state}
  end

  @impl true
  def handle_call(:get_driver_config, _from, %{config: config} = state) do
    {:reply, config.driver_profile_stats, state}
  end

  @impl true
  def handle_cast({:set_driver_config, driver_config}, %{config: config} = state) do
    {:noreply, %{state | config: %{config | driver_profile_stats: driver_config}}}
  end

  @impl true
  def handle_cast(:reset_network, %{graph: network, config: config} = state) do
    network
    |> Network.get_processes()
    |> Enum.each(fn pid -> Agent.stop(pid) end)

    {:noreply, %{state | graph: Network.build_network(config)}}
  end

  @impl true
  def handle_info(:tick, %{graph: network} = state) do
    Process.send_after(self(), :tick, 10)
    {:noreply, %{state | graph: Network.step(network)}}
  end
end
