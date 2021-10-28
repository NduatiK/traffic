defmodule Traffic.Network.Server do
  use GenServer
  alias Traffic.Network.{Road, Junction, Graph}
  alias Traffic.Network

  # Client
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def get_compiled(pid) do
    GenServer.call(pid, :get_compiled)
  end

  # Server (callbacks)
  @impl true
  def init(_) do
    Process.send_after(self(), :tick, 5000)

    {:ok, Network.build_network()}
  end

  @impl true
  def handle_call(:get, _from, network) do
    {:reply, network, network}
  end

  @impl true
  def handle_call(:get_compiled, _from, network) do
    {junctions, roads} = Network.compile_network(network)

    {:reply, {junctions, roads}, network}
  end

  @impl true
  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, 10)
    {:noreply, Network.step(state)}
  end
end
