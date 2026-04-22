defmodule PuedoPhoenix.SnapshotControllerTest do
  use PuedoPhoenix.ConnCase

  describe "GET /api/snapshot" do
    test "returns a snapshot envelope", %{conn: conn} do
      conn = get(conn, ~p"/api/snapshot")
      data = json_response(conn, 200)["data"]

      assert is_map(data)
      assert is_integer(data["schema_version"])
      assert is_integer(data["version"])
      assert is_map(data["roles"])
      assert is_map(data["resources"])
      assert is_list(data["policies"])
      assert is_map(data["conditions"])
    end

    test "reflects stored entities", %{conn: conn} do
      Puedo.put_role(%Puedo.Types.Role{id: "snap_role", inherits: []})

      conn = get(conn, ~p"/api/snapshot")
      data = json_response(conn, 200)["data"]

      assert Map.has_key?(data["roles"], "snap_role")
    end
  end

  describe "GET /api/version" do
    test "returns current version", %{conn: conn} do
      v1 = json_response(get(conn, ~p"/api/version"), 200)["data"]["version"]

      Puedo.put_role(%Puedo.Types.Role{id: "bump_#{System.unique_integer([:positive])}"})

      v2 = json_response(get(conn, ~p"/api/version"), 200)["data"]["version"]

      assert is_integer(v1)
      assert v2 > v1
    end
  end
end
