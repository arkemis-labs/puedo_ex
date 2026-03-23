defmodule Puedo.SnapshotTest do
  use ExUnit.Case, async: true

  alias Puedo.Snapshot
  alias Puedo.Types.{Role, Resource, Policy, Condition}
  alias Puedo.Types.Snapshot, as: SnapshotType

  @sample_snapshot %SnapshotType{
    schema_version: 1,
    version: 42,
    updated_at: ~U[2026-03-19 14:30:00Z],
    roles: %{
      "admin" => %Role{id: "admin", inherits: []},
      "editor" => %Role{id: "editor", inherits: ["viewer"]},
      "viewer" => %Role{id: "viewer", inherits: []}
    },
    resources: %{
      "post" => %Resource{id: "post", actions: ["create", "read", "update", "delete"]},
      "dashboard" => %Resource{id: "dashboard", actions: ["view", "edit", "share"]}
    },
    policies: [
      %Policy{id: "pol_1", role: "editor", resource: "post", actions: ["create", "read", "update"], condition: nil},
      %Policy{id: "pol_2", role: "editor", resource: "post", actions: ["delete"], condition: "is_owner"},
      %Policy{id: "pol_3", role: "admin", resource: "*", actions: ["*"], condition: nil}
    ],
    conditions: %{
      "is_owner" => %Condition{
        name: "is_owner",
        op: :eq,
        field: "subject.id",
        value: %{ref: "resource.owner_id"}
      },
      "same_department" => %Condition{
        name: "same_department",
        op: :and,
        rules: [
          %Condition{name: "same_department", op: :eq, field: "subject.department", value: %{ref: "resource.department"}}
        ]
      }
    }
  }

  describe "to_json/1" do
    test "produces valid JSON" do
      json = Snapshot.to_json(@sample_snapshot)
      assert {:ok, _decoded} = JSON.decode(json)
    end

    test "includes schema_version and version" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert decoded["schema_version"] == 1
      assert decoded["version"] == 42
    end

    test "serializes updated_at as ISO 8601" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert decoded["updated_at"] == "2026-03-19T14:30:00Z"
    end

    test "serializes roles as map with inherits" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert decoded["roles"]["admin"] == %{"inherits" => []}
      assert decoded["roles"]["editor"] == %{"inherits" => ["viewer"]}
    end

    test "serializes resources as map with actions and relations" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert decoded["resources"]["post"]["actions"] == ["create", "read", "update", "delete"]
      assert decoded["resources"]["post"]["relations"] == []
    end

    test "serializes policies as list of objects" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert length(decoded["policies"]) == 3

      pol_1 = Enum.find(decoded["policies"], &(&1["id"] == "pol_1"))
      assert pol_1["role"] == "editor"
      assert pol_1["resource"] == "post"
      assert pol_1["condition"] == nil
    end

    test "serializes conditions with string ops" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert decoded["conditions"]["is_owner"]["op"] == "eq"
      assert decoded["conditions"]["is_owner"]["field"] == "subject.id"
      assert decoded["conditions"]["is_owner"]["value"] == %{"ref" => "resource.owner_id"}
    end

    test "serializes compound conditions with rules" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, decoded} = JSON.decode(json)
      same_dept = decoded["conditions"]["same_department"]
      assert same_dept["op"] == "and"
      assert length(same_dept["rules"]) == 1
    end

    test "null updated_at" do
      snapshot = %{@sample_snapshot | updated_at: nil}
      json = Snapshot.to_json(snapshot)
      {:ok, decoded} = JSON.decode(json)
      assert decoded["updated_at"] == nil
    end
  end

  describe "from_json/1" do
    test "round-trips through to_json and back" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, restored} = Snapshot.from_json(json)

      assert restored.schema_version == @sample_snapshot.schema_version
      assert restored.version == @sample_snapshot.version
      assert restored.updated_at == @sample_snapshot.updated_at
      assert restored.roles == @sample_snapshot.roles
      assert restored.resources == @sample_snapshot.resources
      assert restored.policies == @sample_snapshot.policies
      assert restored.conditions == @sample_snapshot.conditions
    end

    test "converts string ops back to atoms" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, restored} = Snapshot.from_json(json)
      assert restored.conditions["is_owner"].op == :eq
      assert restored.conditions["same_department"].op == :and
    end

    test "rebuilds ref values" do
      json = Snapshot.to_json(@sample_snapshot)
      {:ok, restored} = Snapshot.from_json(json)
      assert restored.conditions["is_owner"].value == %{ref: "resource.owner_id"}
    end

    test "returns error on invalid JSON" do
      assert {:error, _} = Snapshot.from_json("not json")
    end
  end
end
