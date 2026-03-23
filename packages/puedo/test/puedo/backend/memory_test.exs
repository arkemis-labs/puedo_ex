defmodule Puedo.Backend.MemoryTest do
  use ExUnit.Case, async: true

  alias Puedo.Backend.Memory
  alias Puedo.Types.{Role, Resource, Policy, Condition, Snapshot}

  setup do
    {:ok, state} = Memory.init([])
    %{state: state}
  end

  describe "init/1" do
    test "returns ok with initial state" do
      assert {:ok, _state} = Memory.init([])
    end
  end

  describe "load_snapshot/1" do
    test "returns empty snapshot on fresh state", %{state: state} do
      assert {:ok, %Snapshot{} = snapshot} = Memory.load_snapshot(state)
      assert snapshot.version == 0
      assert snapshot.roles == %{}
      assert snapshot.resources == %{}
      assert snapshot.policies == []
      assert snapshot.conditions == %{}
    end

    test "returns snapshot with all stored data", %{state: state} do
      role = %Role{id: "admin"}
      resource = %Resource{id: "post", actions: ["read", "write"]}
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      condition = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: %{ref: "resource.owner_id"}}

      {:ok, state} = Memory.put_role(state, role)
      {:ok, state} = Memory.put_resource(state, resource)
      {:ok, state} = Memory.put_policy(state, policy)
      {:ok, state} = Memory.put_condition(state, condition)

      assert {:ok, %Snapshot{} = snapshot} = Memory.load_snapshot(state)
      assert snapshot.roles == %{"admin" => role}
      assert snapshot.resources == %{"post" => resource}
      assert snapshot.policies == [policy]
      assert snapshot.conditions == %{"is_owner" => condition}
    end
  end

  describe "put_role/2" do
    test "adds a role", %{state: state} do
      role = %Role{id: "editor", inherits: ["viewer"]}
      assert {:ok, state} = Memory.put_role(state, role)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.roles["editor"] == role
    end

    test "overwrites an existing role with the same id", %{state: state} do
      role_v1 = %Role{id: "editor", inherits: []}
      role_v2 = %Role{id: "editor", inherits: ["viewer"]}

      {:ok, state} = Memory.put_role(state, role_v1)
      {:ok, state} = Memory.put_role(state, role_v2)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.roles["editor"] == role_v2
    end
  end

  describe "put_resource/2" do
    test "adds a resource", %{state: state} do
      resource = %Resource{id: "post", actions: ["create", "read", "update", "delete"]}
      assert {:ok, state} = Memory.put_resource(state, resource)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.resources["post"] == resource
    end

    test "overwrites an existing resource with the same id", %{state: state} do
      r1 = %Resource{id: "post", actions: ["read"]}
      r2 = %Resource{id: "post", actions: ["read", "write"]}

      {:ok, state} = Memory.put_resource(state, r1)
      {:ok, state} = Memory.put_resource(state, r2)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.resources["post"] == r2
    end
  end

  describe "put_policy/2" do
    test "adds a policy", %{state: state} do
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      assert {:ok, state} = Memory.put_policy(state, policy)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert policy in snapshot.policies
    end

    test "overwrites an existing policy with the same id", %{state: state} do
      p1 = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      p2 = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read", "write"]}

      {:ok, state} = Memory.put_policy(state, p1)
      {:ok, state} = Memory.put_policy(state, p2)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert length(snapshot.policies) == 1
      assert hd(snapshot.policies) == p2
    end
  end

  describe "put_condition/2" do
    test "adds a condition", %{state: state} do
      condition = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: %{ref: "resource.owner_id"}}
      assert {:ok, state} = Memory.put_condition(state, condition)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.conditions["is_owner"] == condition
    end

    test "adds a compound condition", %{state: state} do
      condition = %Condition{
        name: "same_department",
        op: :and,
        rules: [
          %Condition{name: "dept_match", op: :eq, field: "subject.department", value: %{ref: "resource.department"}}
        ]
      }

      assert {:ok, state} = Memory.put_condition(state, condition)

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.conditions["same_department"] == condition
    end
  end

  describe "delete_role/2" do
    test "removes an existing role", %{state: state} do
      {:ok, state} = Memory.put_role(state, %Role{id: "admin"})
      assert {:ok, state} = Memory.delete_role(state, "admin")

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.roles == %{}
    end

    test "returns ok when role does not exist", %{state: state} do
      assert {:ok, _state} = Memory.delete_role(state, "nonexistent")
    end
  end

  describe "delete_policy/2" do
    test "removes an existing policy", %{state: state} do
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      {:ok, state} = Memory.put_policy(state, policy)
      assert {:ok, state} = Memory.delete_policy(state, "pol_1")

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.policies == []
    end

    test "returns ok when policy does not exist", %{state: state} do
      assert {:ok, _state} = Memory.delete_policy(state, "nonexistent")
    end
  end

  describe "delete_condition/2" do
    test "removes an existing condition", %{state: state} do
      condition = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: "me"}
      {:ok, state} = Memory.put_condition(state, condition)
      assert {:ok, state} = Memory.delete_condition(state, "is_owner")

      {:ok, snapshot} = Memory.load_snapshot(state)
      assert snapshot.conditions == %{}
    end

    test "returns ok when condition does not exist", %{state: state} do
      assert {:ok, _state} = Memory.delete_condition(state, "nonexistent")
    end
  end
end
