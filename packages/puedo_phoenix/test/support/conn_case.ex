defmodule PuedoPhoenix.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PuedoPhoenix.TestEndpoint

      use Phoenix.VerifiedRoutes,
        endpoint: PuedoPhoenix.TestEndpoint,
        router: PuedoPhoenix.TestRouter

      import Plug.Conn
      import Phoenix.ConnTest
      import PuedoPhoenix.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
