import RealtimeLineChart from '../line_chart'

export default
  {
    mounted() {
      this.chart = new RealtimeLineChart(this.el, false)

      this.handleEvent('new-point', ({ label, value }) => {
        this.chart.addPoint(label, value)
      })
    },
    destroyed() {
      this.chart.destroy()
    }
  }
