// Source: https://dev.to/mnishiguchi/real-time-charting-with-elixir-phoenixliveview-chartjs-b4c


// https://www.chartjs.org/docs/3.6.1/getting-started/integration.html#bundlers-webpack-rollup-etc


import Chart from 'chart.js/auto'
import 'chartjs-adapter-luxon'
import ChartStreaming from 'chartjs-plugin-streaming'
Chart.register(ChartStreaming)

Chart.defaults.font.family = "Inter, sans-serif,sanss";

// A wrapper of Chart.js that configures the realtime line chart.
export default class {
  constructor(ctx, showLabels = true) {
    this.showLabels = showLabels;
    this.colors = [
      'rgba(255, 99, 132, 1)',
      'rgba(54, 162, 235, 1)',
      'rgba(255, 206, 86, 1)',
      'rgba(75, 192, 192, 1)',
      'rgba(153, 102, 255, 1)',
      'rgba(255, 159, 64, 1)'
    ]

    const config = {
      type: 'line',
      data: { datasets: [] },
      options: {
        animation: false,
        datasets: {
          // https://www.chartjs.org/docs/3.6.0/charts/line.html#dataset-properties
          line: {
            tension: 0.3
          }
        },
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: showLabels
          },
          // https://nagix.github.io/chartjs-plugin-streaming/2.0.0/guide/options.html
          streaming: {
            duration: 60 * 1000,
            delay: 1500
          }
        },
        scales: {
          x: {
            type: 'realtime'
          },
          y: {
            suggestedMin: 0,
            suggestedMax: 24
          }
        }
      }
    }

    this.chart = new Chart(ctx, config)
  }

  addPoint(label, value) {
    const dataset = this._findDataset(label) || this._createDataset(label)
    dataset.data.push({ x: Date.now(), y: value })
    this.chart.update()
  }

  destroy() {
    this.chart.destroy()
  }

  _findDataset(label) {
    return this.chart.data.datasets.find((dataset) => dataset.label === label)
  }

  _createDataset(label) {
    const newDataset = {
      label, data: [], borderColor: this.colors.pop(),
      hidden: this.showLabels,
    }
    this.chart.data.datasets.push(newDataset)
    return newDataset
  }
}