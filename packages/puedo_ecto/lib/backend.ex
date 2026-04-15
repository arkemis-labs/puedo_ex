defmodule PuedoEcto.Backend do
  @moduledoc """
  `Puedo.Backend` implementation backed by Ecto.

  ## Usage

      PuedoEcto.Backend.init(repo: MyApp.Repo)
  """

  @behaviour Puedo.Backend

  import Ecto.Query
  alias Puedo.Types.{Role, Resource, Policy, Condition, Snapshot}
  alias PuedoEcto.Schema

  @impl true
  def init(opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} ->
        {:ok, %{repo: repo, roles: %{}, resources: %{}, policies: %{}, conditions: %{}}}

      :error ->
        {:error, :missing_repo}
    end
  end

  @impl true
  def load_snapshot(%{repo: repo} = _state) do
    roles =
      repo.all(Schema.Role)
      |> Map.new(fn r -> {r.id, %Role{id: r.id, inherits: r.inherits}} end)

    resources =
      repo.all(Schema.Resource)
      |> Map.new(fn r ->
        {r.id, %Resource{id: r.id, actions: r.actions, relations: r.relations}}
      end)

    policies =
      repo.all(Schema.Policy)
      |> Enum.map(fn p ->
        %Policy{
          id: p.id,
          role: p.role,
          resource: p.resource,
          actions: Enum.map(p.actions, &to_string/1),
          condition: p.condition
        }
      end)

    conditions =
      repo.all(Schema.Condition)
      |> Map.new(fn c -> {c.name, db_to_condition(c)} end)

    {:ok,
     %Snapshot{
       roles: roles,
       resources: resources,
       policies: policies,
       conditions: conditions
     }}
  rescue
    e -> {:error, e}
  end

  @impl true
  def put_role(%{repo: repo} = state, %Role{} = role) do
    attrs = %{id: role.id, inherits: role.inherits}

    case handle_put(repo, Schema.Role, attrs, :id) do
      {:ok, _} -> {:ok, put_in(state, [:roles, role.id], role)}
      {:error, _} = err -> err
    end
  end

  @impl true
  def put_resource(%{repo: repo} = state, %Resource{} = resource) do
    attrs = %{id: resource.id, actions: resource.actions, relations: resource.relations}

    case handle_put(repo, Schema.Resource, attrs, :id) do
      {:ok, _} -> {:ok, put_in(state, [:resources, resource.id], resource)}
      {:error, _} = err -> err
    end
  end

  @impl true
  def put_policy(%{repo: repo} = state, %Policy{} = policy) do
    attrs = %{
      id: policy.id,
      role: policy.role,
      resource: policy.resource,
      actions: policy.actions,
      condition: policy.condition
    }

    case handle_put(repo, Schema.Policy, attrs, :id) do
      {:ok, _} -> {:ok, put_in(state, [:policies, policy.id], policy)}
      {:error, _} = err -> err
    end
  end

  @impl true
  def put_condition(%{repo: repo} = state, %Condition{} = condition) do
    attrs = condition_to_attrs(condition)

    case handle_put(repo, Schema.Condition, attrs, :name) do
      {:ok, _} -> {:ok, put_in(state, [:conditions, condition.name], condition)}
      {:error, _} = err -> err
    end
  end

  @impl true
  def delete_role(%{repo: repo} = state, id) do
    repo.delete_all(from(p in Schema.Role, where: p.id == ^id))
    {:ok, %{state | roles: Map.delete(state.roles, id)}}
  rescue
    e -> {:error, e}
  end

  @impl true
  def delete_policy(%{repo: repo} = state, id) do
    repo.delete_all(from(p in Schema.Policy, where: p.id == ^id))
    {:ok, %{state | policies: Map.delete(state.policies, id)}}
  rescue
    e -> {:error, e}
  end

  @impl true
  def delete_condition(%{repo: repo} = state, name) do
    repo.delete_all(from(p in Schema.Condition, where: p.name == ^name))
    {:ok, %{state | conditions: Map.delete(state.conditions, name)}}
  rescue
    e -> {:error, e}
  end

  # --- Repo helpers ---

  defp handle_put(repo, schema, attrs, conflict_target) do
    struct(schema)
    |> schema.changeset(attrs)
    |> repo.insert(
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: conflict_target
    )
  end

  # --- Conversion helpers ---

  defp db_to_condition(row) do
    %Condition{
      name: row.name,
      op: row.op,
      field: row.field,
      value: row.value,
      rules: row.rules && Enum.map(row.rules, &map_to_condition/1)
    }
  end

  defp map_to_condition(%{"name" => name, "op" => op} = map) do
    %Condition{
      name: name,
      op: String.to_existing_atom(op),
      field: map["field"],
      value: map["value"],
      rules: map["rules"] && Enum.map(map["rules"], &map_to_condition/1)
    }
  end

  defp condition_to_attrs(%Condition{} = c) do
    %{
      name: c.name,
      op: c.op,
      field: c.field,
      value: c.value,
      rules: c.rules && Enum.map(c.rules, &condition_to_map/1)
    }
  end

  defp condition_to_map(%Condition{} = c) do
    %{
      "name" => c.name,
      "op" => to_string(c.op),
      "field" => c.field,
      "value" => c.value,
      "rules" => c.rules && Enum.map(c.rules, &condition_to_map/1)
    }
  end
end
