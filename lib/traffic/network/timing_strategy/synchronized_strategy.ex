defmodule Traffic.Network.Timing.SynchonizedStrategy do
  @moduledoc """
  Just wait a bit and keep switching
  """
  alias Traffic.Network.Timing.Strategy
  use Strategy
  use TypedStruct

  typedstruct module: State do
    field :lights, {Strategy.light(), Strategy.light()}
    field :now, integer()
    field :last_change, integer()
    field :time_in_yellow, integer()
    field :time_in_green, integer()
    field :time_in_red, integer()
  end

  @impl Strategy
  def name() do
    "Randomized Naive"
  end

  @impl Strategy
  def init() do
    %{}
  end

  @impl Strategy
  def add_road(state, road) do
    state
    |> Map.put(
      road,
      %State{
        now: 0,
        lights: {:red, :yellow},
        last_change: 0,
        time_in_yellow: 25,
        time_in_green: 100,
        time_in_red: 100
      }
    )
    |> Enum.with_index()
    |> Enum.map(fn {{k, v}, i} ->
      {k,
       %{
         v
         | time_in_red: Enum.count(state) * 100,
           last_change: i * 100
       }}
    end)
    |> Enum.into(%{})
  end

  @impl Strategy
  def tick(state) do
    state
    |> Enum.map(fn {k, v} ->
      {k, tick_state(v)}
    end)
    |> Enum.into(%{})
  end

  defp tick_state(%State{} = state) do
    state = %{state | now: state.now + 1}

    time_per_state =
      case state.lights do
        {:red, _} ->
          state.time_in_red

        {:yellow, _} ->
          state.time_in_yellow

        {:green, _} ->
          state.time_in_green
      end

    if state.now - state.last_change > time_per_state do
      state
      |> Map.put(:lights, transition(state.lights))
      |> Map.put(:last_change, state.now)
    else
      state
    end
  end
end
