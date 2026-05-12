defmodule PuedoTest do
  use ExUnit.Case

  alias Puedo.Types.{Role, Resource, Policy, Condition}

  setup do
    start_supervised!({Puedo.Supervisor, []})
    :ok
  end

  describe "policy management" do
    test "put and list roles" do
      assert :ok = Puedo.put_role(%Role{id: "admin"})
      assert :ok = Puedo.put_role(%Role{id: "editor", inherits: ["viewer"]})

      roles = Puedo.list_roles()
      assert length(roles) == 2
    end

    test "put and list resources" do
      assert :ok = Puedo.put_resource(%Resource{id: "post", actions: ["read", "write"]})

      resources = Puedo.list_resources()
      assert length(resources) == 1
    end

    test "put and list policies" do
      policy = %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]}
      assert :ok = Puedo.put_policy(policy)

      policies = Puedo.list_policies()
      assert length(policies) == 1
    end

    test "put and list conditions" do
      condition = %Condition{name: "is_owner", op: :eq, field: "subject.id", value: %{ref: "resource.owner_id"}}
      assert :ok = Puedo.put_condition(condition)

      conditions = Puedo.list_conditions()
      assert length(conditions) == 1
    end

    test "delete role" do
      :ok = Puedo.put_role(%Role{id: "admin"})
      assert :ok = Puedo.delete_role("admin")
      assert Puedo.list_roles() == []
    end

    test "delete policy" do
      :ok = Puedo.put_policy(%Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]})
      assert :ok = Puedo.delete_policy("pol_1")
      assert Puedo.list_policies() == []
    end

    test "delete condition" do
      :ok = Puedo.put_condition(%Condition{name: "is_owner", op: :eq, field: "subject.id", value: "me"})
      assert :ok = Puedo.delete_condition("is_owner")
      assert Puedo.list_conditions() == []
    end

    test "get_role returns the role or nil" do
      assert Puedo.get_role("admin") == nil
      :ok = Puedo.put_role(%Role{id: "admin"})
      assert %Role{id: "admin"} = Puedo.get_role("admin")
    end

    test "get_resource returns the resource or nil" do
      assert Puedo.get_resource("post") == nil
      :ok = Puedo.put_resource(%Resource{id: "post", actions: ["read", "write"]})
      assert %Resource{id: "post"} = Puedo.get_resource("post")
    end

    test "get_condition returns the condition or nil" do
      assert Puedo.get_condition("is_owner") == nil
      :ok = Puedo.put_condition(%Condition{name: "is_owner", op: :eq, field: "subject.id", value: "me"})
      assert %Condition{name: "is_owner"} = Puedo.get_condition("is_owner")
    end
  end

  describe "can?/3" do
    test "full flow: role + policy + evaluation" do
      :ok = Puedo.put_role(%Role{id: "viewer"})
      :ok = Puedo.put_role(%Role{id: "editor", inherits: ["viewer"]})
      :ok = Puedo.put_resource(%Resource{id: "post", actions: ["read", "create", "delete"]})
      :ok = Puedo.put_policy(%Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})
      :ok = Puedo.put_policy(%Policy{id: "pol_2", role: "editor", resource: "post", actions: ["create"]})

      viewer = %{id: "user:bob", role: "viewer"}
      editor = %{id: "user:anne", role: "editor"}

      assert Puedo.can?(viewer, "read", "post")
      refute Puedo.can?(viewer, "create", "post")

      assert Puedo.can?(editor, "read", "post")
      assert Puedo.can?(editor, "create", "post")
      refute Puedo.can?(editor, "delete", "post")
    end

    test "with condition and resource context" do
      :ok = Puedo.put_role(%Role{id: "editor"})
      :ok = Puedo.put_resource(%Resource{id: "post", actions: ["delete"]})
      :ok = Puedo.put_condition(%Condition{name: "is_owner", op: :eq, field: "subject.id", value: %{ref: "resource.owner_id"}})
      :ok = Puedo.put_policy(%Policy{id: "pol_1", role: "editor", resource: "post", actions: ["delete"], condition: "is_owner"})

      subject = %{id: "user:anne", role: "editor"}

      assert Puedo.can?(subject, "delete", "post", %{owner_id: "user:anne"})
      refute Puedo.can?(subject, "delete", "post", %{owner_id: "user:bob"})
    end
  end

  describe "introspection" do
    test "snapshot returns full state" do
      :ok = Puedo.put_role(%Role{id: "admin"})
      :ok = Puedo.put_policy(%Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]})

      snapshot = Puedo.snapshot()
      assert snapshot.version == 2
      assert map_size(snapshot.roles) == 1
      assert length(snapshot.policies) == 1
    end

    test "version returns current version" do
      assert Puedo.version() == 0
      :ok = Puedo.put_role(%Role{id: "admin"})
      assert Puedo.version() == 1
    end
  end
end
