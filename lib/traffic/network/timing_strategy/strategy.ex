defmodule Traffic.Network.Timing.Strategy do
  @type light :: :green | :yellow | :red
  @doc """
  The name of the strategy.
  """
  @callback name() :: String.t()

  @doc """
  Gives current state given the current and prev state, last change time, current_time and some opts.
  """
  @callback tick({light(), light()}, integer(), integer(), Keyword.t()) ::
              light()
end
