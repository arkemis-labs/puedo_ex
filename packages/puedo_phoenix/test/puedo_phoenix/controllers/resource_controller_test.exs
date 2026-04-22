defmodule PuedoPhoenix.ResourceControllerTest do
  use PuedoPhoenix.ConnCase

  describe "GET /api/resources" do
    test "returns list including stored resources", %{conn: conn} do
      id = unique_id("posts")

      Puedo.put_resource(%Puedo.Types.Resource{
        id: id,
        actions: ["read", "write"],
        relations: ["owner"]
      })

      conn = get(conn, ~p"/api/resources")
      data = json_response(conn, 200)["data"]

      assert Enum.any?(
               data,
               &(&1["id"] == id and &1["actions"] == ["read", "write"] and
                   &1["relations"] == ["owner"])
             )
    end
  end

  describe "POST /api/resources" do
    test "creates a resource", %{conn: conn} do
      id = unique_id("posts")

      conn =
        post(conn, ~p"/api/resources", %{
          id: id,
          actions: ["read", "write"],
          relations: ["owner"]
        })

      assert %{
               "data" => %{
                 "actions" => ["read", "write"],
                 "relations" => ["owner"]
               }
             } = json_response(conn, 201)

      assert %Puedo.Types.Resource{} = Enum.find(Puedo.list_resources(), &(&1.id == id))
    end

    test "creates a resource with default actions/relations", %{conn: conn} do
      id = unique_id("bare")
      conn = post(conn, ~p"/api/resources", %{id: id})

      assert %{"data" => %{"actions" => [], "relations" => []}} = json_response(conn, 201)
    end

    test "returns error when id is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/resources", %{actions: []})
      assert json_response(conn, 400)["error"] =~ "missing"
    end
  end

  defp unique_id(prefix), do: "#{prefix}_#{System.unique_integer([:positive])}"
end
