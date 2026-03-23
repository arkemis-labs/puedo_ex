defmodule Puedo.Snapshot do
  alias Puedo.Types.{Snapshot, Role, Resource, Policy, Condition}

  @spec to_json(Snapshot.t()) :: String.t()
  def to_json(snapshot) do
    snapshot |> serialize() |> JSON.encode!()
  end

  @spec from_json(String.t()) :: {:ok, Snapshot.t()} | {:error, term()}
  def from_json(json) do
    case JSON.decode(json) do
      {:ok, data} -> {:ok, deserialize(data)}
      {:error, _} = error -> error
    end
  end

  defp serialize(snapshot) do
    %{
      "schema_version" => snapshot.schema_version,
      "version" => snapshot.version,
      "updated_at" => serialize_datetime(snapshot.updated_at),
      "roles" => Map.new(snapshot.roles, fn {id, role} ->
        {id, %{"inherits" => role.inherits}}
      end),
      "resources" => Map.new(snapshot.resources, fn {id, resource} ->
        {id, %{"actions" => resource.actions, "relations" => resource.relations}}
      end),
      "policies" => Enum.map(snapshot.policies, fn policy ->
        %{
          "id" => policy.id,
          "role" => policy.role,
          "resource" => policy.resource,
          "actions" => policy.actions,
          "condition" => policy.condition
        }
      end),
      "conditions" => Map.new(snapshot.conditions, fn {name, condition} ->
        {name, serialize_condition(condition)}
      end)
    }
  end

  defp serialize_condition(condition) do
    base = %{"op" => Atom.to_string(condition.op)}

    if condition.rules do
      Map.put(base, "rules", Enum.map(condition.rules, &serialize_condition/1))
    else
      base
      |> Map.put("field", condition.field)
      |> Map.put("value", serialize_value(condition.value))
    end
  end

  defp serialize_value(%{ref: path}), do: %{"ref" => path}
  defp serialize_value(value), do: value

  defp serialize_datetime(nil), do: nil
  defp serialize_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp deserialize(data) do
    %Snapshot{
      schema_version: data["schema_version"],
      version: data["version"],
      updated_at: deserialize_datetime(data["updated_at"]),
      roles: Map.new(data["roles"], fn {id, role} ->
        {id, %Role{id: id, inherits: role["inherits"]}}
      end),
      resources: Map.new(data["resources"], fn {id, resource} ->
        {id, %Resource{id: id, actions: resource["actions"], relations: resource["relations"]}}
      end),
      policies: Enum.map(data["policies"], fn policy ->
        %Policy{
          id: policy["id"],
          role: policy["role"],
          resource: policy["resource"],
          actions: policy["actions"],
          condition: policy["condition"]
        }
      end),
      conditions: Map.new(data["conditions"], fn {name, condition} ->
        {name, deserialize_condition(name, condition)}
      end)
    }
  end

  defp deserialize_condition(name, data) do
    op = String.to_existing_atom(data["op"])

    if data["rules"] do
      %Condition{
        name: name,
        op: op,
        rules: Enum.map(data["rules"], fn rule ->
          deserialize_condition(rule["name"] || name, rule)
        end)
      }
    else
      %Condition{
        name: name,
        op: op,
        field: data["field"],
        value: deserialize_value(data["value"])
      }
    end
  end

  defp deserialize_value(%{"ref" => path}), do: %{ref: path}
  defp deserialize_value(value), do: value

  defp deserialize_datetime(nil), do: nil
  defp deserialize_datetime(str) do
    {:ok, dt, _offset} = DateTime.from_iso8601(str)
    dt
  end
end
