defmodule Traffic.Network.Junction do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Network.Road

  typedstruct do
    field :left_light, :red | :yellow | :green
    field :right_light, :red | :yellow | :green
    # field :roads, list(Road.t()), default: []
    field :left_road, Road.t()
    field :right_road, Road.t()
  end

  def step(%Junction{} = junction) do
    # TODO: should pass through junction
    # TODO: block if junction blocked
    # TODO: block return info on if has space

    left_road_ = Road.step(junction.left_road, [:lanes_to_right])
    right_road_ = Road.step(junction.right_road, [:lanes_to_left])

    right_road =
      Road.join_road(
        right_road_.road,
        :left,
        left_road_.exited_to_right
      )

    left_road =
      Road.join_road(
        left_road_.road,
        :right,
        right_road_.exited_to_left
      )

    %{junction | left_road: left_road, right_road: right_road}
  end
end

defimpl Inspect, for: Traffic.Network.Junction do
  def inspect(junction, _opts) do
    "" <>
      "|              |\n" <>
      "|              |\n" <>
      "|              |\n" <>
      "|              |\n" <>
      "|              |\n" <>
      "|              |\n"

    # "#{match_light(:red, junction.light)}\n" <>
    #   "#{match_light(:yellow, junction.light)}\n" <>
    #   "#{match_light(:green, junction.light)}\n"

    # Kernel.inspect(junction)

    [junction.left_road, junction.right_road]
    |> Enum.map(&Kernel.inspect/1)
    |> Enum.map(&String.split(&1, "\n"))
    |> Enum.zip()
    |> Enum.map(
      &(Tuple.to_list(&1)
        |> Enum.join("|#{row_light(junction.left_light)}| |#{row_light(junction.right_light)}|"))
    )
    |> Enum.join("\n")
  end

  def row_light(light) do
    match_light(:red, light) <>
      match_light(:yellow, light) <>
      match_light(:green, light)
  end

  def match_light(light, light) do
    "◉"
  end

  def match_light(_, _) do
    "◎"
  end
end
