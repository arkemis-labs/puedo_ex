defmodule Puedo.StoreTest do
  use ExUnit.Case, async: true

  alias Puedo.Store
  alias Puedo.Types.{Role, Resource, Policy, Condition, Snapshot}

  setup do
    store = start_supervised!({Store, backend: {Puedo.Backend.Memory, []}})
    %{store: store}
  end

  describe "start_link/1" do
    test "starts with the given backend" do
      assert {:ok, pid} = Store.start_link(backend: {Puedo.Backend.Memory, []})
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "snapshot/1" do
    test "returns empty snapshot on fresh store", %{store: store} do
      assert %Snapshot{} = snapshot = Store.snapshot(store)
      assert snapshot.version == 0
      assert snapshot.roles == %{}
      assert snapshot.resources == %{}
      assert snapshot.policies == []
      assert snapshot.conditions == %{}
    end
  end

  describe "put_role/2" do
    test "adds a role and increments version", %{store: store} do
      role = %Role{id: "admin"}
      assert :ok = Store.put_role(store, role)

      snapshot = Store.snapshot(store)
      assert snapshot.roles["admin"] == role
      assert snapshot.version == 1
    end

    test "role is readable from ETS without message passing", %{store: store} do
      role = %Role{id: "editor", inherits: ["viewer"]}
      :ok = Store.put_role(store, role)

      assert Store.get_role(store, "editor") == role
    end
  end

  describe "put_resource/2" do
    test "adds a resource and increments version", %{store: store} do
      resource = %Resource{id: "post", actions: ["create", "read"]}
      assert :ok = Store.put_resource(store, resource)

      snapshot = Store.snapshot(store)
      assert snapshot.resources["post"] == resource
      assert snapshot.version == 1
    end
  end

  describe "put_policy/2" do
    test "adds a policy and increments version", %{store: store} do
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      assert :ok = Store.put_policy(store, policy)

      snapshot = Store.snapshot(store)
      assert policy in snapshot.policies
      assert snapshot.version == 1
    end
  end

  describe "put_condition/2" do
    test "adds a condition and increments version", %{store: store} do
      condition = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: %{ref: "resource.owner_id"}}
      assert :ok = Store.put_condition(store, condition)

      snapshot = Store.snapshot(store)
      assert snapshot.conditions["is_owner"] == condition
      assert snapshot.version == 1
    end
  end

  describe "delete_role/2" do
    test "removes a role and increments version", %{store: store} do
      :ok = Store.put_role(store, %Role{id: "admin"})
      assert :ok = Store.delete_role(store, "admin")

      snapshot = Store.snapshot(store)
      assert snapshot.roles == %{}
      assert snapshot.version == 2
    end
  end

  describe "delete_policy/2" do
    test "removes a policy and increments version", %{store: store} do
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      :ok = Store.put_policy(store, policy)
      assert :ok = Store.delete_policy(store, "pol_1")

      snapshot = Store.snapshot(store)
      assert snapshot.policies == []
      assert snapshot.version == 2
    end
  end

  describe "delete_condition/2" do
    test "removes a condition and increments version", %{store: store} do
      :ok = Store.put_condition(store, %Condition{name: "is_owner", op: :eq, field: "subject.id", value: "me"})
      assert :ok = Store.delete_condition(store, "is_owner")

      snapshot = Store.snapshot(store)
      assert snapshot.conditions == %{}
      assert snapshot.version == 2
    end
  end

  describe "version tracking" do
    test "each write increments version", %{store: store} do
      assert Store.version(store) == 0

      :ok = Store.put_role(store, %Role{id: "admin"})
      assert Store.version(store) == 1

      :ok = Store.put_role(store, %Role{id: "editor"})
      assert Store.version(store) == 2

      :ok = Store.delete_role(store, "admin")
      assert Store.version(store) == 3
    end
  end

  describe "ETS reads" do
    test "get_role/2 returns nil for missing role", %{store: store} do
      assert Store.get_role(store, "nonexistent") == nil
    end

    test "get_resource/2 reads from ETS", %{store: store} do
      resource = %Resource{id: "post", actions: ["read"]}
      :ok = Store.put_resource(store, resource)
      assert Store.get_resource(store, "post") == resource
    end

    test "get_policy/2 returns nil for missing policy", %{store: store} do
      assert Store.get_policy(store, "nonexistent") == nil
    end

    test "get_policy/2 reads from ETS", %{store: store} do
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      :ok = Store.put_policy(store, policy)
      assert Store.get_policy(store, "pol_1") == policy
    end

    test "get_condition/2 reads from ETS", %{store: store} do
      condition = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: "me"}
      :ok = Store.put_condition(store, condition)
      assert Store.get_condition(store, "is_owner") == condition
    end

    test "list_roles/1 returns all roles from ETS", %{store: store} do
      r1 = %Role{id: "admin"}
      r2 = %Role{id: "editor", inherits: ["viewer"]}
      :ok = Store.put_role(store, r1)
      :ok = Store.put_role(store, r2)

      roles = Store.list_roles(store)
      assert length(roles) == 2
      assert r1 in roles
      assert r2 in roles
    end

    test "list_resources/1 returns all resources from ETS", %{store: store} do
      r1 = %Resource{id: "post", actions: ["read"]}
      r2 = %Resource{id: "dashboard", actions: ["view"]}
      :ok = Store.put_resource(store, r1)
      :ok = Store.put_resource(store, r2)

      resources = Store.list_resources(store)
      assert length(resources) == 2
      assert r1 in resources
      assert r2 in resources
    end

    test "list_policies/1 returns all policies from ETS", %{store: store} do
      p1 = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      p2 = %Policy{id: "pol_2", role: "editor", resource: "post", actions: ["read"]}
      :ok = Store.put_policy(store, p1)
      :ok = Store.put_policy(store, p2)

      policies = Store.list_policies(store)
      assert length(policies) == 2
      assert p1 in policies
      assert p2 in policies
    end

    test "list_conditions/1 returns all conditions from ETS", %{store: store} do
      c1 = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: "me"}
      c2 = %Condition{name: "same_dept", op: :eq, field: "subject.dept", value: %{ref: "resource.dept"}}
      :ok = Store.put_condition(store, c1)
      :ok = Store.put_condition(store, c2)

      conditions = Store.list_conditions(store)
      assert length(conditions) == 2
      assert c1 in conditions
      assert c2 in conditions
    end
  end
end
