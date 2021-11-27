defmodule Traffic.Network.Timing.RandomizedNaiveStrategy do
  @moduledoc """
  Just wait a bit and keep switching
  """
  alias Traffic.Network.Timing.Strategy
  @behaviour Strategy
  use TypedStruct

  typedstruct module: State do
    field(:lights, {Strategy.light(), Strategy.light()})
    field(:now, integer())
    field(:start_after, integer())
    field(:last_change, integer())
    field(:time_in_yellow, integer())
    field(:time_per_state, integer())
  end

  @impl Strategy
  def name() do
    "Naive"
  end

  @impl Strategy
  @spec init() :: State.t()
  def init() do
    %State{
      now: 0,
      lights: {:red, :yellow},
      last_change: 0,
      time_in_yellow: 25,
      time_per_state: 100,
      start_after: :rand.uniform(100)
    }
  end

  @impl Strategy
  def tick(%State{start_after: start_after, now: now} = state) when start_after > now do
    state
    |> Map.put(:now, state.now + 1)
    # Also bump last change so that everything is offset
    |> Map.put(:last_change, state.now + 1)
    |> wrap()
  end

  @impl Strategy
  def tick(%State{} = state) do
    state = %{state | now: state.now + 1}

    time_per_state =
      case state.lights do
        {:yellow, _} ->
          state.time_in_yellow

        _ ->
          state.time_per_state
      end

    state =
      if state.now - state.last_change > time_per_state do
        state
        |> Map.put(:lights, transition(state.lights))
        |> Map.put(:last_change, state.now)
      else
        state
      end

    wrap(state)
  end

  def wrap(state) do
    {
      elem(state.lights, 0),
      state
    }
  end

  defp transition({:yellow, :red}), do: {:green, :yellow}
  defp transition({:yellow, :green}), do: {:red, :yellow}
  defp transition({:red, :yellow}), do: {:yellow, :red}
  defp transition({:green, :yellow}), do: {:yellow, :green}
end
