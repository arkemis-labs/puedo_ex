defmodule PuedoEcto.FakeRepo do
  @moduledoc """
  In-process fake repo for testing. Uses the process dictionary for isolation —
  each test process gets its own store, so async: true is safe.
  """

  def reset, do: Process.put(__MODULE__, %{})

  def all(schema) when is_atom(schema) do
    store()
    |> Map.get(schema, %{})
    |> Map.values()
  end

  def insert(%Ecto.Changeset{valid?: false} = changeset, _opts) do
    {:error, changeset}
  end

  def insert(%Ecto.Changeset{valid?: true} = changeset, _opts) do
    record = Ecto.Changeset.apply_changes(changeset)
    schema = record.__struct__
    pk_field = schema.__schema__(:primary_key) |> hd()
    pk_value = Map.fetch!(record, pk_field)
    put_record(schema, pk_value, record)
    {:ok, record}
  end

  def delete_all(%Ecto.Query{} = query) do
    schema = elem(query.from.source, 1)
    pk_field = schema.__schema__(:primary_key) |> hd()
    [{value, _type}] = hd(query.wheres).params

    records = store() |> Map.get(schema, %{})
    remaining = Map.reject(records, fn {_k, r} -> Map.get(r, pk_field) == value end)
    deleted = map_size(records) - map_size(remaining)
    update_store(schema, fn _ -> remaining end)
    {deleted, nil}
  end

  defp store, do: Process.get(__MODULE__, %{})

  defp put_record(schema, pk, record) do
    update_store(schema, &Map.put(&1, pk, record))
  end

  defp update_store(schema, fun) do
    current = store()
    updated = Map.update(current, schema, %{}, fun)
    Process.put(__MODULE__, updated)
  end
end
