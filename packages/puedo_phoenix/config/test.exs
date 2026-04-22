import Config

config :puedo_phoenix,
  endpoint: PuedoPhoenix.TestEndpoint,
  router: PuedoPhoenix.TestRouter

config :puedo_phoenix, PuedoPhoenix.TestEndpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ajYn4AZ0Nl+n/Ke4s2XHjVlVk7RzywRJgrlJkykIOal6Y4bMA/PH8uoxwYFy4YFO",
  server: false,
  render_errors: [
    formats: [json: PuedoPhoenix.ErrorJSON],
    layout: false
  ]

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
