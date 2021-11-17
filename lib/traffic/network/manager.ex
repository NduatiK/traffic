defmodule Traffic.Network.Manager do
  use GenServer
  use TypedStruct

  alias Traffic.Network.ChildSupervisor, as: ChildSup
  alias Traffic.Network.RoadServer

  typedstruct module: State do
    field(:counters, map(), default: %{vehicle: 0, road: 0, junction: 0})
    field(:name, :string, enforced: true)
    field(:config, Traffic.Network.Config.t(), enforced: true)
    field(:graph, Graph.t())
  end

  alias Traffic.Network.ChildSupervisor

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      %{
        name: Keyword.get(opts, :name),
        config: Keyword.get(opts, :config)
      },
      name: Traffic.via_tuple(__MODULE__, Keyword.get(opts, :name))
    )
  end

  @impl true
  def init(state) do
    state = %State{
      name: state.name,
      graph: Graph.new(type: :undirected),
      config: state.config
    }

    Process.send_after(self(), :tick, 5000)

    {:ok, state}
  end

  def start_road(manager, junction1, junction2)
      when is_pid(junction1) and is_pid(junction2) do
    manager
    |> get_manager()
    |> GenServer.call({:start_road, junction1, junction2})
  end

  def start_junction(manager, x, y) when is_number(x) and is_number(y) do
    manager
    |> get_manager()
    |> GenServer.call({:start_junction, x, y})
  end

  def start_vehicle(manager) do
    manager
    |> get_manager()
    |> GenServer.call({:start_vehicle})
  end

  def get_graph(manager) do
    manager
    |> get_manager()
    |> GenServer.call(:get_graph)
  end

  def get_driver_config(manager) do
    manager
    |> get_manager()
    |> GenServer.call(:get_driver_config)
  end

  def set_driver_config(manager, config) do
    manager
    |> get_manager()
    |> GenServer.cast({:set_driver_config, config})
  end

  @impl true
  def handle_call({:start_road, junction1, junction2}, _from, %State{} = state) do
    {state, id} = increase_counter(state, :road)

    {:ok, pid} =
      ChildSupervisor.start_road(
        ChildSup.via(state.name),
        id,
        state.name,
        junction1,
        junction2,
        state.config
      )

    new_graph = Graph.add_edge(state.graph, junction1, junction2, label: pid)

    # existing_roads_junction_1 =
    state.graph
    |> Graph.edges(junction1)
    |> Enum.each(fn edge ->
      if edge.v1 == junction1 do
        RoadServer.add_linked_road(edge.label, :left, pid)
        RoadServer.add_linked_road(pid, :right, edge.label)
      else
        RoadServer.add_linked_road(edge.label, :right, pid)
        RoadServer.add_linked_road(pid, :left, edge.label)
      end
    end)

    state.graph
    |> Graph.edges(junction2)
    |> Enum.each(fn edge ->
      if edge.v2 == junction2 do
        RoadServer.add_linked_road(edge.label, :right, pid)
        RoadServer.add_linked_road(pid, :left, edge.label)
      else
        RoadServer.add_linked_road(edge.label, :left, pid)
        RoadServer.add_linked_road(pid, :right, edge.label)
      end
    end)

    IO.inspect("----")
    {:reply, {:ok, pid}, %{state | graph: new_graph}}
  end

  @impl true
  def handle_call({:start_junction, x, y}, _from, %State{} = state) do
    {state, id} = increase_counter(state, :junction)

    {:ok, pid} =
      ChildSupervisor.start_junction(ChildSup.via(state.name), id, state.name, x, y, state.config)

    new_graph = Graph.add_vertex(state.graph, pid)

    {:reply, {:ok, pid}, %{state | graph: new_graph}}
  end

  @impl true
  def handle_call({:start_vehicle}, _from, %State{} = state) do
    {state, id} = increase_counter(state, :vehicle)

    {:ok, pid} =
      ChildSupervisor.start_vehicle(ChildSup.via(state.name), id, state.name, state.config)

    {:reply, {:ok, pid}, state}
  end

  @impl true
  def handle_call(:get_graph, _from, %State{} = state) do
    {:reply, state.graph, state}
  end

  @impl true
  def handle_call(:get_driver_config, _from, %State{} = state) do
    {:reply, state.config.driver_profile_stats, state}
  end

  @impl true
  def handle_cast({:set_driver_config, driver_config}, %State{config: config} = state) do
    {:noreply,
     %State{
       state
       | config: %{config | driver_profile_stats: driver_config}
     }}
  end

  @impl true
  def handle_info(:tick, %State{} = state) do
    # Process.send_after(self(), :tick, 100)
    # IO.inspect(:tick)
    {:noreply, state}
  end

  defp increase_counter(%{counters: counters} = state, key) do
    old_count = Map.get(counters, key, 0)
    counters = put_in(state.counters, [key], old_count + 1)
    {%{state | counters: counters}, old_count}
  end

  def get_manager(manager) when is_atom(manager), do: via(manager)
  def get_manager(pid) when is_pid(pid), do: pid

  defp via(manager) when is_atom(manager), do: Traffic.via_tuple(__MODULE__, manager)
end
