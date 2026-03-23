defmodule Puedo.Supervisor do
  use Supervisor

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    backend = Keyword.get(opts, :backend, {Puedo.Backend.Memory, []})

    children = [
      {Puedo.Store, [backend: backend, name: Puedo.Store]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
