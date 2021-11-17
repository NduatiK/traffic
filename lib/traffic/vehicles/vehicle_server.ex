defmodule Traffic.Vehicles.VehicleServer do
  use GenServer

  # Client
  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts,
      name: Traffic.via_tuple(__MODULE__, {Keyword.get(opts, :name), Keyword.get(opts, :id)})
    )
  end

  # Server (callbacks)
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  # @impl true
  # def handle_call(:get_graph, _from, %{graph: network} = state) do
  #   {:reply, network, state}
  # end

  # @impl true
  # def handle_cast(:get_graph, %{graph: network} = state) do
  #   {:noreply, state}
  # end

  # @impl true
  # def handle_info(:tick, %{graph: network, config: config} = state) do
  #   Process.send_after(self(), :tick, 10)
  #   {:noreply, %{state | graph: Network.step(network, config)}}
  # end
end
