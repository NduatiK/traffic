defmodule Traffic.Evolution do
  use GenServer

  use TypedStruct
  alias Traffic.Network.JunctionServer
  alias Traffic.Network.Timing.GeneticEvolutionStrategy.GE

  typedstruct module: State do
    field :simulations, list(), default: []
  end

  @evolve_delay 10_000

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :evolve, @evolve_delay)

    state = %State{}
    {:ok, state}
  end

  def register_junction(sim_name, pid) do
    GenServer.cast(__MODULE__, {:register_junction, sim_name, pid})
  end

  def handle_cast({:register_junction, sim_name, {pid, id}}, _from, %State{} = state) do
    sims =
      state.simulations
      |> Map.update(sim_name, %{id => pid}, fn junctions ->
        junctions
        |> Map.put(id, pid)
      end)

    {:noreply, %{state | simulations: sims}}
  end

  def handle_info(:evolve, state) do
    Process.send_after(self(), :evolve, @evolve_delay)

    IO.inspect(:evolve)

    state.simulations
    |> Enum.map(fn {name, sims} ->
      1..map_size(sims)
      |> Enum.map(fn id ->
        Task.async(fn ->
          {
            JunctionServer.get_timing_config(sims[id])
            |> Map.drop(:meta)
            |> Map.to_list(),
            sims[id]
          }
        end)
      end)
      |> Enum.map(&Task.await/1)
      |> then(&{&1, Traffic.Statistics.get_average_wait_time(name)})
    end)
    |> GE.evolve([])
    |> Enum.map(fn {config, pid} ->
      JunctionServer.set_timing_config(pid, config |> Enum.into(%{}))
    end)

    {:noreply, state}
  end
end
