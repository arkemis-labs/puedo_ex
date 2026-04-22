defmodule PuedoPhoenix.PolicyController do
  use Phoenix.Controller, formats: [:json]

  alias Puedo.Types.Policy

  def index(conn, _params) do
    policies = Puedo.list_policies()
    json(conn, %{data: Enum.map(policies, &policy_to_json/1)})
  end

  def create(
        conn,
        %{"id" => id, "role" => role, "resource" => resource, "actions" => actions} = params
      ) do
    policy = %Policy{
      id: id,
      role: role,
      resource: resource,
      actions: actions,
      condition: Map.get(params, "condition")
    }

    case Puedo.put_policy(policy) do
      :ok ->
        conn
        |> put_status(:created)
        |> json(%{data: policy_to_json(policy)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing required fields: id, role, resource, actions"})
  end

  def delete(conn, %{"id" => id}) do
    case Puedo.delete_policy(id) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  # todo: derive from Policy?
  defp policy_to_json(%Policy{} = policy) do
    %{
      id: policy.id,
      role: policy.role,
      resource: policy.resource,
      actions: policy.actions,
      condition: policy.condition
    }
  end
end
