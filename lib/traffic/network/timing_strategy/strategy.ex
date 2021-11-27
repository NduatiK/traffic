defmodule Traffic.Network.Timing.Strategy do
  @type light :: :green | :yellow | :red
  @type road_state :: %{
          :lights => {light(), light()},
          optional(any()) => any()
        }
  @type state :: %{required(atom()) => road_state()}
  @doc """
  The name of the strategy.
  """
  @callback name() :: String.t()

  @doc """
  The name of the strategy.
  """
  @callback add_road(state(), any()) :: state()

  @doc """
  """
  @callback init() :: state()

  @doc """
  Gives current state given the current and prev state, last change time, current_time and some opts.
  """
  @callback tick(state()) :: state()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  def transition({:yellow, :red}), do: {:green, :yellow}
  def transition({:yellow, :green}), do: {:red, :yellow}
  def transition({:red, :yellow}), do: {:yellow, :red}
  def transition({:green, :yellow}), do: {:yellow, :green}

  def get_color(state, road) do
    state
    |> Map.get(road)
    |> Map.get(:lights)
    |> elem(0)
  end
end
