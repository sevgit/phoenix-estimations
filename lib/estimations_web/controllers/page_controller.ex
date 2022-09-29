defmodule EstimationsWeb.PageController do
  use EstimationsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
