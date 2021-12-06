defmodule TrafficWeb.Components.LineChart do
  @moduledoc """
  Adapted from:
  Context Library samples
  https://github.com/mindok/contex-samples/blob/master/lib/contexsample_web/live/pointplot.ex
  """
  use Surface.Component
  alias Contex.{LinePlot, PointPlot, Dataset, Plot}

  prop(data, :map)

  @impl true
  def render(assigns) do
    ~F"""
    {build_pointplot(@data, chart_opts())}
    """
  end

  def chart_opts() do
    %{
      series: 1,
      points: 30,
      title: "Average Delay",
      type: "line",
      smoothed: "yes",
      colour_scheme: "default",
      show_legend: "no",
      custom_x_scale: "no",
      custom_y_scale: "no",
      custom_y_ticks: "no",
      time_series: "no",
      series_columns: ["Y"]
    }
  end

  def build_pointplot(dataset, chart_options) do
    options = [
      colour_palette: :pastel1,
      # custom_x_scale: custom_x_scale,
      # custom_y_scale: custom_y_scale,
      smoothed: chart_options.smoothed == "yes"
    ]

    plot_options =
      case chart_options.show_legend do
        "yes" -> %{legend_setting: :legend_right}
        _ -> %{}
      end

    plot =
      Plot.new(dataset, LinePlot, 384, 300, options)
      |> Plot.titles(chart_options.title, nil)
      |> Plot.plot_options(plot_options)

    Plot.to_svg(plot)
  end
end
