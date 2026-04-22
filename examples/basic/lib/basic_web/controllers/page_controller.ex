defmodule BasicWeb.PageController do
  use BasicWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
