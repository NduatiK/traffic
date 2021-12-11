defmodule Traffic.Network.Timing.GeneticEvolutionStrategy do
  @moduledoc """
  Just wait a bit and keep switching
  """
  alias Traffic.Network.Timing.Strategy
  use Strategy
  use TypedStruct

  typedstruct module: RoadState do
    field(:lights, {Strategy.light(), Strategy.light()})
    field(:last_change, integer())
    field(:time_in_yellow, integer())
    field(:time_in_green, integer())
    field(:time_in_red, integer())
    field(:start_after, integer())
  end

  @impl Strategy
  def name() do
    "Randomized Synchonized Naive"
  end

  @impl Strategy
  def init() do
    %{
      meta: %{
        now: 0,
        start_after: :rand.uniform(100)
      }
    }
  end

  @impl Strategy
  def add_road(state, road) do
    state
    |> Map.put(
      road,
      %RoadState{
        lights: {:red, :yellow},
        last_change: 0,
        time_in_yellow: 25,
        time_in_green: 100,
        time_in_red: 100,
        start_after: 0
      }
    )
    |> map_with_index(fn {{k, v}, i} ->
      {k,
       %{
         v
         | time_in_red: road_count(state) * 100,
           last_change: i * 100
       }}
    end)
    |> Enum.into(%{})
  end

  def road_count(state) do
    Enum.count(state) - 1
  end

  @impl Strategy
  def tick(%{meta: %{start_after: start_after, now: now}} = state) when start_after > now do
    state
    |> put_in([:meta, :now], state.meta.now + 1)
    |> map(fn {k, v} ->
      {k, %{v | last_change: v.last_change + 1}}
    end)
  end

  @impl Strategy
  def tick(state) do
    state
    |> put_in([:meta, :now], state.meta.now + 1)
    |> map(fn {k, v} ->
      {k, tick_state(v, state.meta.now)}
    end)
  end

  defp tick_state(%RoadState{} = state, now) do
    time_per_state =
      case state.lights do
        {:red, _} ->
          state.time_in_red

        {:yellow, _} ->
          state.time_in_yellow

        {:green, _} ->
          state.time_in_green
      end

    if now - state.last_change > time_per_state do
      state
      |> Map.put(:lights, transition(state.lights))
      |> Map.put(:last_change, now)
    else
      state
    end
  end

  defmodule GE do
    use TypedStruct

    typedstruct module: Chromosome do
      alias Traffic.Network.Timing.GeneticEvolutionStrategy.RoadState

      field(:name, atom())
      field(:timings, list({RoadState, integer()}))
    end

    alias Traffic.Statistics
    # population of simulations
    def evolve(population, opts) do
      :timer.sleep(30_000)

      population
      |> evaluation(opts)
      |> selection(opts)
      |> crossover(opts)
      |> mutation(opts)
      |> share()
      |> evolve(opts)
    end

    defp evaluation(population, _opts) do
      population
      |> Enum.sort_by(&Statistics.get_average_wait_time(&1.name), :desc)
    end

    defp selection(population, _opts) do
      population
      |> Enum.chunk_every(2)
      |> Enum.map(&List.to_tuple/1)
    end

    defp mutation(population, _opts) do
      population
      |> Enum.map(fn chromosome ->
        if :rand.uniform() < 0.05 do
          chromosome.timings
          |> Enum.count()
          |> randomize_chromosome()
        else
          chromosome
        end
      end)
    end

    defp randomize_chromosome(road_count) do
      1..road_count
      |> Enum.map(fn i ->
        green = 5 + :rand.uniform(250)

        %RoadState{
          lights:
            if i == 0 do
              {:green, :yellow}
            else
              {:red, :yellow}
            end,
          last_change: 0,
          time_in_yellow: 25,
          time_in_green: green,
          time_in_red: 260 - green
        }
      end)
      |> synchronize_lights()
    end

    def synchronize_lights(roads) do
      total_time =
        roads
        |> Enum.map(& &1.time_in_green)
        |> Enum.sum()

      roads
      |> Enum.with_index()
      |> Enum.map(fn {road, i} ->
        %{
          road
          | time_in_red: total_time - road.time_in_green,
            last_change: i * 100,
            start_after: if(i == 0, do: 0, else: total_time - road.time_in_green)
        }
      end)
    end

    defp crossover(population, _opts) do
      Enum.reduce(population, [], fn {p1, p2}, acc ->
        crossover_point = :rand.uniform(1000)
        {h1, t1} = Enum.split(p1.timings, crossover_point)
        {h2, t2} = Enum.split(p2.timings, crossover_point)

        [
          %{p1 | timings: synchronize_lights(h1 ++ t2)},
          %{p2 | timings: synchronize_lights(h2 ++ t1)}
          | acc
        ]
      end)
    end

    defp share(population) do
      # TODO: Clear averages
      # TODO: Update junctions
      population
    end
  end
end
