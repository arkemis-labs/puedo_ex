defmodule PuedoPhoenix.RoleControllerTest do
  use PuedoPhoenix.ConnCase

  setup do
    # Clean up any roles from previous tests
    for role <- Puedo.list_roles() do
      Puedo.delete_role(role.id)
    end

    :ok
  end

  describe "GET /api/roles" do
    test "returns empty list when no roles", %{conn: conn} do
      conn = get(conn, ~p"/api/roles")
      assert json_response(conn, 200) == %{"data" => []}
    end

    test "returns existing roles", %{conn: conn} do
      Puedo.put_role(%Puedo.Types.Role{id: "admin", inherits: []})
      Puedo.put_role(%Puedo.Types.Role{id: "editor", inherits: ["viewer"]})

      conn = get(conn, ~p"/api/roles")
      data = json_response(conn, 200)["data"]

      assert length(data) == 2
      assert Enum.any?(data, &(&1["id"] == "admin"))
      assert Enum.any?(data, &(&1["id"] == "editor"))
    end
  end

  describe "POST /api/roles" do
    test "creates a role", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", %{id: "viewer", inherits: []})

      assert %{"data" => %{"id" => "viewer", "inherits" => []}} =
               json_response(conn, 201)

      assert %Puedo.Types.Role{id: "viewer"} = Enum.find(Puedo.list_roles(), &(&1.id == "viewer"))
    end

    test "creates a role with inheritance", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", %{id: "editor", inherits: ["viewer"]})

      assert %{"data" => %{"id" => "editor", "inherits" => ["viewer"]}} =
               json_response(conn, 201)
    end

    test "returns error when id is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", %{inherits: []})
      assert json_response(conn, 400)["error"] =~ "missing"
    end
  end

  describe "DELETE /api/roles/:id" do
    test "deletes an existing role", %{conn: conn} do
      Puedo.put_role(%Puedo.Types.Role{id: "temp"})

      conn = delete(conn, ~p"/api/roles/temp")
      assert response(conn, 204)

      assert Puedo.list_roles() |> Enum.find(&(&1.id == "temp")) == nil
    end
  end
end
