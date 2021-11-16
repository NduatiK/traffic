defmodule Traffic.Network.Timing.NaiveStrategy do
  alias Traffic.Network.Timing.Strategy
  @behaviour Strategy

  @impl Strategy
  def name() do
    "Naive"
  end

  @impl Strategy
  def tick({:yellow, _} = state, last_change, time_now, opts) do
    time_per_state = Keyword.get(opts, :time_in_yellow, 100)

    if time_now - last_change > time_per_state do
      {transition(state), time_now}
    else
      {state, last_change}
    end
  end

  @impl Strategy
  def tick(state, last_change, time_now, opts) do
    time_per_state = Keyword.get(opts, :time_per_state, 500)

    if time_now - last_change > time_per_state do
      {transition(state), time_now}
    else
      {state, last_change}
    end
  end

  defp transition({:yellow, :red}), do: {:green, :yellow}
  defp transition({:yellow, :green}), do: {:red, :yellow}
  defp transition({:red, :yellow}), do: {:yellow, :red}
  defp transition({:green, :yellow}), do: {:yellow, :green}
end
