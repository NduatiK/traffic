defmodule Traffic.Network do
  @doc """
  Best followed up by a Network.build_network(name)
  """
  def start_simulation(name, opts \\ []) do
    opts =
      Keyword.put_new(opts, :config, %Traffic.Network.Config{
        timing_strategy: Traffic.Network.Timing.NaiveStrategy
      })

    Traffic.Simulation.start_simulation(name, opts)
  end

  def start_simulation_and_network(name, opts \\ []) do
    :timer.sleep(10)
    start_simulation(name, opts)
    :timer.sleep(10)
    build_network(name)
  end

  def build_network(name) do
    {:ok, junction_1} = start_junction(name, 10 * 5, 10 * 5)
    {:ok, junction_2} = start_junction(name, 50 * 5, 10 * 5)
    {:ok, junction_3} = start_junction(name, 70 * 5, 30 * 5)
    {:ok, junction_4} = start_junction(name, 50 * 5, 50 * 5)
    {:ok, junction_5} = start_junction(name, 10 * 5, 50 * 5)

    {:ok, _road_0} = start_road(name, junction_1, junction_2)
    {:ok, _road_1} = start_road(name, junction_2, junction_3)
    {:ok, _road_2} = start_road(name, junction_3, junction_4)
    {:ok, _road_3} = start_road(name, junction_4, junction_5)
    {:ok, _road_4} = start_road(name, junction_5, junction_1)
    {:ok, _road_5} = start_road(name, junction_4, junction_2)
  end

  def start_road(name, junction1, junction2) do
    Traffic.Network.Manager.start_road(name, junction1, junction2)
  end

  def start_junction(name, x, y) do
    Traffic.Network.Manager.start_junction(name, x, y)
  end
end
