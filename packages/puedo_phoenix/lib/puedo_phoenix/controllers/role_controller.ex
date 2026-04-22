defmodule PuedoPhoenix.RoleController do
  use Phoenix.Controller, formats: [:json]

  alias Puedo.Types.Role

  def index(conn, _params) do
    roles = Puedo.list_roles()
    json(conn, %{data: Enum.map(roles, &role_to_json/1)})
  end

  def create(conn, %{"id" => id} = params) do
    role = %Role{
      id: id,
      inherits: Map.get(params, "inherits", [])
    }

    case Puedo.put_role(role) do
      :ok ->
        conn
        |> put_status(:created)
        |> json(%{data: role_to_json(role)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "missing required field: id"})
  end

  def delete(conn, %{"id" => id}) do
    case Puedo.delete_role(id) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  # todo: derive from Role?
  defp role_to_json(%Role{} = role) do
    %{id: role.id, inherits: role.inherits}
  end
end
