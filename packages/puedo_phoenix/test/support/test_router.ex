defmodule PuedoPhoenix.TestRouter do
  use Phoenix.Router
  import PuedoPhoenix.Router

  pipeline :puedo_api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :puedo_api
    puedo_dashboard "/", dashboard: false
  end
end
