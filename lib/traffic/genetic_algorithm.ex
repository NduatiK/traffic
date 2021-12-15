defmodule Traffic.GeneticAlgorithm do
  use TypedStruct
  import Traffic.Network.Timing.GeneticEvolutionStrategy
  alias Traffic.Network.Timing.GeneticEvolutionStrategy.RoadState

  typedstruct module: Chromosome do
    field(:name, atom())
    field(:timings, list({RoadState, integer()}))
  end

  def evolve(population, opts \\ []) do
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
          |> new_synchronized_list()}, pid}
      else
        {{road, chromosome}, pid}
      end
    end)
  end
end
