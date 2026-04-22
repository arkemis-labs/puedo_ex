defmodule PuedoPhoenix.ResourceController do
  use Phoenix.Controller, formats: [:json]

  alias Puedo.Types.Resource

  def index(conn, _params) do
    resources = Puedo.list_resources()
    json(conn, %{data: Enum.map(resources, &resource_to_json/1)})
  end

  def create(conn, %{"id" => id} = params) do
    resource = %Resource{
      id: id,
      actions: Map.get(params, "actions", []),
      relations: Map.get(params, "relations", [])
    }

    case Puedo.put_resource(resource) do
      :ok ->
        conn
        |> put_status(:created)
        |> json(%{data: resource_to_json(resource)})

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

  # todo: delete resource?

  # todo: derive from Resource?
  defp resource_to_json(%Resource{} = resource) do
    %{id: resource.id, actions: resource.actions, relations: resource.relations}
  end
end
