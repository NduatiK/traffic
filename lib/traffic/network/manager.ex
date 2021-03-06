defmodule Traffic.Network.Manager do
  use GenServer, restart: :temporary

  use TypedStruct

  alias Traffic.Network.SimulationComponentSupervisor, as: ChildSup
  alias Traffic.Network.RoadServer
  alias Traffic.Network.JunctionServer

  typedstruct module: State do
    field(:counters, map(), default: %{vehicle: 0, road: 0, junction: 0})
    field(:name, :string, enforce: true)
    field(:config, Traffic.Network.Config.t(), enforce: true)
    field(:graph, Graph.t())
    field(:paused, boolean(), default: false)
  end

  alias Traffic.Network.SimulationComponentSupervisor

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
      graph: Graph.new(type: :directed),
      config: state.config
    }

    {:ok, state}
  end

  def start_road(manager, junction1, junction2, arterial \\ false)
      when is_pid(junction1) and is_pid(junction2) do
    manager
    |> get_manager()
    |> GenServer.call({:start_road, junction1, junction2, arterial})
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

  def get_config(manager) do
    manager
    |> get_manager()
    |> GenServer.call(:get_config)
  end

  def get_driver_config(manager) do
    manager
    |> get_config()
    |> then(& &1.driver_profile_stats)
  end

  def set_driver_config(manager, config) do
    manager
    |> get_manager()
    |> GenServer.cast({:set_driver_config, config})
  end

  def pause(manager) do
    manager
    |> get_manager()
    |> GenServer.cast(:pause)
  end

  def reset_network(name) when is_atom(name) do
    config = get_config(name)
    Traffic.Network.SimulationSupervisor.stop(name)
    Traffic.Network.start_simulation_and_network(name, config.timing_strategy)
  end

  def get_pause_status(manager) do
    manager
    |> get_manager()
    |> GenServer.call(:get_pause_status)
  end

  @impl true
  def handle_call({:start_road, junction1, junction2, arterial}, _from, %State{} = state) do
    {state, id} = increase_counter(state, :road)

    {:ok, pid} =
      SimulationComponentSupervisor.start_road(
        ChildSup.via(state.name),
        id,
        state.name,
        junction1,
        junction2,
        state.config
      )

    label = {pid, arterial}
    new_graph = Graph.add_edge(state.graph, junction1, junction2, label: label)

    # existing_roads_junction_1 =

    JunctionServer.add_linked_road(junction1, {:left, pid})
    JunctionServer.add_linked_road(junction2, {:right, pid})

    state.graph
    |> Graph.edges(junction1)
    |> Enum.each(fn edge ->
      if edge.v1 == junction1 do
        RoadServer.add_linked_road(edge.label, {:left, :left}, label)
        RoadServer.add_linked_road(label, {:left, :left}, edge.label)
      else
        RoadServer.add_linked_road(edge.label, {:right, :left}, label)
        RoadServer.add_linked_road(label, {:left, :right}, edge.label)
      end
    end)

    state.graph
    |> Graph.edges(junction2)
    |> Enum.each(fn edge ->
      if edge.v2 == junction2 do
        RoadServer.add_linked_road(edge.label, {:right, :right}, label)
        RoadServer.add_linked_road(label, {:right, :right}, edge.label)
      else
        RoadServer.add_linked_road(edge.label, {:left, :right}, label)
        RoadServer.add_linked_road(label, {:right, :left}, edge.label)
      end
    end)

    {:reply, {:ok, pid}, %{state | graph: new_graph}}
  end

  @impl true
  def handle_call({:start_junction, x, y}, _from, %State{} = state) do
    {state, id} = increase_counter(state, :junction)

    {:ok, pid} =
      SimulationComponentSupervisor.start_junction(
        ChildSup.via(state.name),
        id,
        state.name,
        x,
        y,
        state.config
      )

    new_graph = Graph.add_vertex(state.graph, pid)

    {:reply, {:ok, pid}, %{state | graph: new_graph}}
  end

  @impl true
  def handle_call({:start_vehicle}, _from, %State{} = state) do
    {state, id} = increase_counter(state, :vehicle)

    {:ok, pid} =
      SimulationComponentSupervisor.start_vehicle(
        ChildSup.via(state.name),
        id,
        state.name,
        state.config
      )

    {:reply, {:ok, pid}, state}
  end

  @impl true
  def handle_call(:get_graph, _from, %State{} = state) do
    {:reply, state.graph, state}
  end

  @impl true
  def handle_call(:get_pause_status, _from, %State{} = state) do
    {:reply, state.paused, state}
  end

  @impl true
  def handle_call(:get_config, _from, %State{} = state) do
    {:reply, state.config, state}
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
  def handle_cast(:pause, %State{} = state) do
    state.name
    |> ChildSup.via()
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn
      {_, pid, :worker, _} ->
        Task.async(fn -> GenServer.cast(pid, :pause) end)

      _ ->
        nil
    end)

    {:noreply, %{state | paused: not state.paused}}
  end

  @impl true
  def handle_info(_, %State{} = state) do
    # Here to accept the Task async callbacks
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
