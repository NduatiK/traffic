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
    "Genetic Algorithm Strategy"
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

  def new_synchronized_list(count) do
    1..count
    |> Enum.map(fn i ->
      green = 25 + :rand.uniform(200 - 50)

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
        time_in_red: 200 - green
      }
    end)
    |> synchronize_lights()
  end

  defp synchronize_lights(roads) do
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
end
