defmodule Traffic.Network.Timing.Strategy do
  @type light :: :green | :yellow | :red
  @type state :: %{lights: {light(), light()}}
  @doc """
  The name of the strategy.
  """
  @callback name() :: String.t()

  @doc """
  """
  @callback init() :: state()

  @doc """
  Gives current state given the current and prev state, last change time, current_time and some opts.
  """
  @callback tick(state()) :: {light(), state()}
end
