defmodule Traffic.Geometry do
  def distance({x1, y1}, {x2, y2}) do
    :math.sqrt(
      :math.pow(y2 - y1, 2) +
        :math.pow(x2 - x1, 2)
    )
  end

  def angle({x1, y1}, {x2, y2}) do
    :math.atan2(
      y1 - y2,
      x1 - x2
    ) *
      180 / :math.pi()
  end
end
