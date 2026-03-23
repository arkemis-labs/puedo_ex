defmodule Puedo.Evaluator do
  @type subject :: %{
          required(:id) => String.t(),
          required(:role) => String.t(),
          optional(atom()) => term()
        }
  @type resource_context :: %{optional(atom()) => term()}

  @spec can?(GenServer.server(), subject(), String.t(), String.t(), resource_context()) ::
          boolean()
  def can?(store, subject, action, resource, resource_context \\ %{}) do
    roles = resolve_roles(store, subject.role, MapSet.new())
    policies = Puedo.Store.list_policies(store)

    policies
    |> Enum.filter(fn policy ->
      matches_role?(policy, roles) and
        matches_resource?(policy, resource) and
        matches_action?(policy, action)
    end)
    |> Enum.any?(fn policy ->
      case policy.condition do
        nil ->
          true

        name ->
          condition = Puedo.Store.get_condition(store, name)
          Puedo.Condition.evaluate(condition, %{subject: subject, resource: resource_context})
      end
    end)
  end

  defp resolve_roles(store, role_id, seen) do
    if MapSet.member?(seen, role_id) do
      seen
    else
      seen = MapSet.put(seen, role_id)

      case Puedo.Store.get_role(store, role_id) do
        nil -> seen
        role -> Enum.reduce(role.inherits, seen, &resolve_roles(store, &1, &2))
      end
    end
  end

  defp matches_role?(policy, roles), do: MapSet.member?(roles, policy.role)
  defp matches_resource?(policy, resource), do: policy.resource == "*" or policy.resource == resource
  defp matches_action?(policy, action), do: "*" in policy.actions or action in policy.actions
end
