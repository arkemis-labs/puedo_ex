{:ok, _} = Puedo.Supervisor.start_link(backend: {Puedo.Backend.Memory, []})
{:ok, _} = PuedoPhoenix.TestEndpoint.start_link()

ExUnit.start()
