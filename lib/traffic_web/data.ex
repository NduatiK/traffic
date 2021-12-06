defmodule TrafficWeb.Data do
  alias Contex.{LinePlot, PointPlot, Dataset, Plot}

  @test_data (
               rand_in_range = fn start, end_ ->
                 :rand.uniform_real() * (end_ - start) + start
               end

               data =
                 for i <- 1..30 do
                   x = i * 5 + rand_in_range.(0.0, 3.0)

                   series_data =
                     for s <- 1..2 do
                       val = s * 8.0 + rand_in_range.(x * (0.1 * s), x * (0.35 * s))
                       # simulate nils in data
                       case s == 2 and ((i > 3 and i < 6) or (i > 7 and i < 10)) do
                         true -> nil
                         _ -> val
                       end
                     end

                   [x | series_data]
                 end

               series_cols =
                 for s <- 1..2 do
                   "Series #{s}"
                 end

               #  test_data = Dataset.new(data, [series_cols])
               test_data = Dataset.new(data, ["X" | series_cols])

               # options = Map.put(options, :series_columns, series_cols)

               # %{
               #   test_data: test_data
               #   # chart_options: options
               #   # prev_series: series,
               #   # prev_points: points,
               #   # prev_time_series: time_series
               # }
             )

  def test_data(), do: @test_data

  def from_queue(queue) do
    queue
    |> :queue.to_list()
    |> from_list()
  end

  def from_list(list) do
    list
    |> Enum.with_index()
    |> Enum.map(&{elem(&1, 1), elem(&1, 0)})
    |> Dataset.new(["X", "Y"])
  end
end
