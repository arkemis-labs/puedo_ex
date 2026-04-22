defmodule PuedoPhoenix.PolicyControllerTest do
  use PuedoPhoenix.ConnCase

  setup do
    for policy <- Puedo.list_policies() do
      Puedo.delete_policy(policy.id)
    end

    :ok
  end

  describe "GET /api/policies" do
    test "returns empty list when no policies", %{conn: conn} do
      conn = get(conn, ~p"/api/policies")
      assert json_response(conn, 200) == %{"data" => []}
    end

    test "returns existing policies", %{conn: conn} do
      Puedo.put_policy(%Puedo.Types.Policy{
        id: "p1",
        role: "admin",
        resource: "posts",
        actions: ["read", "write"]
      })

      Puedo.put_policy(%Puedo.Types.Policy{
        id: "p2",
        role: "viewer",
        resource: "posts",
        actions: ["read"],
        condition: "is_owner"
      })

      conn = get(conn, ~p"/api/policies")
      data = json_response(conn, 200)["data"]

      assert length(data) == 2
      assert Enum.any?(data, &(&1["id"] == "p1"))
      assert Enum.any?(data, &(&1["id"] == "p2" && &1["condition"] == "is_owner"))
    end
  end

  describe "POST /api/policies" do
    test "creates a policy", %{conn: conn} do
      conn =
        post(conn, ~p"/api/policies", %{
          id: "p1",
          role: "admin",
          resource: "posts",
          actions: ["read", "write"]
        })

      assert %{
               "data" => %{
                 "id" => "p1",
                 "role" => "admin",
                 "resource" => "posts",
                 "actions" => ["read", "write"],
                 "condition" => nil
               }
             } = json_response(conn, 201)

      assert %Puedo.Types.Policy{id: "p1"} =
               Enum.find(Puedo.list_policies(), &(&1.id == "p1"))
    end

    test "creates a policy with a condition", %{conn: conn} do
      conn =
        post(conn, ~p"/api/policies", %{
          id: "p2",
          role: "viewer",
          resource: "posts",
          actions: ["read"],
          condition: "is_owner"
        })

      assert %{"data" => %{"condition" => "is_owner"}} = json_response(conn, 201)
    end

    test "returns error when required fields are missing", %{conn: conn} do
      conn = post(conn, ~p"/api/policies", %{id: "p3"})
      assert json_response(conn, 400)["error"] =~ "missing"
    end
  end

  describe "DELETE /api/policies/:id" do
    test "deletes an existing policy", %{conn: conn} do
      Puedo.put_policy(%Puedo.Types.Policy{
        id: "temp",
        role: "admin",
        resource: "posts",
        actions: ["read"]
      })

      conn = delete(conn, ~p"/api/policies/temp")
      assert response(conn, 204)

      assert Puedo.list_policies() |> Enum.find(&(&1.id == "temp")) == nil
    end
  end
end
