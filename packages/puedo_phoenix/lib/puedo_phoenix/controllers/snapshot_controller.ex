defmodule PuedoPhoenix.SnapshotController do
  use Phoenix.Controller, formats: [:json]

  def show(conn, _params) do
    {:ok, snapshot} = Puedo.snapshot() |> Puedo.Snapshot.to_json() |> JSON.decode()
    json(conn, %{data: snapshot})
  end

  def version(conn, _params) do
    json(conn, %{data: %{version: Puedo.snapshot().version}})
  end
end
