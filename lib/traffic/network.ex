defmodule Traffic.Network do
  @doc """
  Best followed up by a Network.build_network(name)
  """
  def start_simulation(name, strategy) do
    Traffic.SimulationListSupervisor.start_simulation(name, strategy)
  end

  def start_simulation_and_network(name, strategy) do
    :timer.sleep(10)
    start_simulation(name, strategy)
    :timer.sleep(10)
    build_network(name)
  end

  def build_network(name) do
    junctions =
      for x <- 0..4 do
        for y <- 0..4 do
          {:ok, junction} = start_junction(name, 50 + 200 * x, 50 + 200 * y)
          junction
        end
      end

    for x <- 0..3 do
      for y <- 0..4 do
        if not (x in [2] and y not in [2, 3]) do
          junction_1 =
            junctions
            |> Enum.at(x)
            |> Enum.at(y)

          junction_2 =
            junctions
            |> Enum.at(x + 1)
            |> Enum.at(y)

          {:ok, _} = start_road(name, junction_1, junction_2, x == 2)
        end
      end
    end

    for x <- 0..4 do
      for y <- 0..3 do
        junction_1 =
          junctions
          |> Enum.at(x)
          |> Enum.at(y)

        junction_2 =
          junctions
          |> Enum.at(x)
          |> Enum.at(y + 1)

        {:ok, _} = start_road(name, junction_1, junction_2)
      end
    end
  end

  def start_road(name, junction1, junction2, arterial \\ false) do
    Traffic.Network.Manager.start_road(name, junction1, junction2, arterial)
  end

  def start_junction(name, x, y) do
    Traffic.Network.Manager.start_junction(name, x, y)
  end
end
