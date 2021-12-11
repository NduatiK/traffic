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
    green = 25 + :rand.uniform(200 - 50)

    road_state = %RoadState{
      lights: {:red, :yellow},
      last_change: 0,
      time_in_yellow: 25,
      time_in_green: green,
      time_in_red: 200 - green
    }

    state
    |> Map.put(road, road_state)
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
    alias Traffic.Statistics

    typedstruct module: Chromosome do
      alias Traffic.Network.Timing.GeneticEvolutionStrategy.RoadState

      field(:name, atom())
      field(:timings, list({RoadState, integer()}))
    end

    def evolve(population, opts) do
      population
      |> evaluation(opts)
      |> selection(opts)
      |> crossover(opts)
      |> mutation(opts)
    end

    defp evaluation(population, _opts) do
      population
      |> Enum.sort_by(&elem(&1, 1), :asc)
      |> Enum.map(&elem(&1, 0))
    end

    defp selection(population, _opts) do
      population
      |> Enum.chunk_every(2)
      |> Enum.map(&List.to_tuple/1)
    end

    defp crossover(population, _opts) do
      Enum.reduce(population, [], fn {{{road1, chromosomes_1}, pid1},
                                      {{road2, chromosomes_2}, pid2}},
                                     acc ->
        crossover_point = :rand.uniform(Enum.count(chromosomes_1))
        {h1, t1} = Enum.split(chromosomes_1, crossover_point)
        {h2, t2} = Enum.split(chromosomes_2, crossover_point)

        [
          {{road1, h1 ++ t2}, pid1},
          {{road2, h2 ++ t1}, pid2}
          | acc
        ]
      end)
    end

    defp mutation(population, _opts) do
      population
      |> Enum.map(fn {{road, chromosome}, pid} ->
        if :rand.uniform() < 0.05 do
          {{road,
            chromosome
            |> Enum.count()
            |> randomize_chromosome()}, pid}
        else
          {{road, chromosome}, pid}
        end
      end)
    end

    defp randomize_chromosome(road_count) do
      1..road_count
      |> Enum.map(fn i ->
        green = 25 + :rand.uniform(200 - 50)

        state = %RoadState{
          lights:
            if i == 0 do
              {:green, :yellow}
            else
              {:red, :yellow}
            end,
          last_change: 0,
          time_in_yellow: 25,
          time_in_green: green,
          time_in_red: 200 - green
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

    defp share(population) do
      # TODO: Clear averages
      # TODO: Update junctions
      population
    end
  end
end
