defmodule PuedoPhoenix.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :puedo_phoenix

  socket "/live", Phoenix.LiveView.Socket

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_puedo_phoenix_test_key",
    signing_salt: "test_salt"

  plug PuedoPhoenix.TestRouter
end
