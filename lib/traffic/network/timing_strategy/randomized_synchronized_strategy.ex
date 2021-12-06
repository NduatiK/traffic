defmodule Traffic.Network.Timing.RandomizedSynchonizedStrategy do
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
        time_in_red: 100
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
end
