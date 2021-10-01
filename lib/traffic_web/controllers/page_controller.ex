defmodule TrafficWeb.PageController do
  use TrafficWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
