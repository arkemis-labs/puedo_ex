defmodule Puedo.EvaluatorTest do
  use ExUnit.Case, async: true

  alias Puedo.Store
  alias Puedo.Evaluator
  alias Puedo.Types.{Role, Resource, Policy, Condition}

  setup do
    store = start_supervised!({Store, backend: {Puedo.Backend.Memory, []}})

    # Set up a basic RBAC structure
    :ok = Store.put_resource(store, %Resource{id: "post", actions: ["create", "read", "update", "delete"]})
    :ok = Store.put_resource(store, %Resource{id: "dashboard", actions: ["view", "edit"]})

    :ok = Store.put_role(store, %Role{id: "viewer", inherits: []})
    :ok = Store.put_role(store, %Role{id: "editor", inherits: ["viewer"]})
    :ok = Store.put_role(store, %Role{id: "admin", inherits: []})

    %{store: store}
  end

  describe "basic permission checks" do
    test "returns false when no policies exist", %{store: store} do
      subject = %{id: "user:anne", role: "viewer"}
      refute Evaluator.can?(store, subject, "read", "post")
    end

    test "returns true when a matching policy exists", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})

      subject = %{id: "user:anne", role: "viewer"}
      assert Evaluator.can?(store, subject, "read", "post")
    end

    test "returns false when action is not in policy", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})

      subject = %{id: "user:anne", role: "viewer"}
      refute Evaluator.can?(store, subject, "delete", "post")
    end

    test "returns false when resource does not match", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})

      subject = %{id: "user:anne", role: "viewer"}
      refute Evaluator.can?(store, subject, "view", "dashboard")
    end

    test "returns false when role does not match", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["read"]})

      subject = %{id: "user:anne", role: "viewer"}
      refute Evaluator.can?(store, subject, "read", "post")
    end
  end

  describe "role inheritance" do
    test "inherits permissions from parent role", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})

      subject = %{id: "user:anne", role: "editor"}
      assert Evaluator.can?(store, subject, "read", "post")
    end

    test "child role has its own permissions plus inherited", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})
      :ok = Store.put_policy(store, %Policy{id: "pol_2", role: "editor", resource: "post", actions: ["create", "update"]})

      subject = %{id: "user:anne", role: "editor"}
      assert Evaluator.can?(store, subject, "read", "post")
      assert Evaluator.can?(store, subject, "create", "post")
      assert Evaluator.can?(store, subject, "update", "post")
      refute Evaluator.can?(store, subject, "delete", "post")
    end

    test "deep inheritance chain", %{store: store} do
      :ok = Store.put_role(store, %Role{id: "super_admin", inherits: ["admin"]})
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["delete"]})

      subject = %{id: "user:anne", role: "super_admin"}
      assert Evaluator.can?(store, subject, "delete", "post")
    end

    test "handles circular inheritance without infinite loop", %{store: store} do
      :ok = Store.put_role(store, %Role{id: "role_a", inherits: ["role_b"]})
      :ok = Store.put_role(store, %Role{id: "role_b", inherits: ["role_a"]})
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "role_a", resource: "post", actions: ["read"]})

      subject = %{id: "user:anne", role: "role_b"}
      assert Evaluator.can?(store, subject, "read", "post")
    end
  end

  describe "wildcard policies" do
    test "wildcard resource matches any resource", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "admin", resource: "*", actions: ["*"]})

      subject = %{id: "user:anne", role: "admin"}
      assert Evaluator.can?(store, subject, "read", "post")
      assert Evaluator.can?(store, subject, "edit", "dashboard")
    end

    test "wildcard action matches any action", %{store: store} do
      :ok = Store.put_policy(store, %Policy{id: "pol_1", role: "admin", resource: "post", actions: ["*"]})

      subject = %{id: "user:anne", role: "admin"}
      assert Evaluator.can?(store, subject, "create", "post")
      assert Evaluator.can?(store, subject, "delete", "post")
      refute Evaluator.can?(store, subject, "view", "dashboard")
    end
  end

  describe "conditions" do
    test "policy with passing condition returns true", %{store: store} do
      :ok = Store.put_condition(store, %Condition{
        name: "is_owner",
        op: :eq,
        field: "subject.id",
        value: %{ref: "resource.owner_id"}
      })
      :ok = Store.put_policy(store, %Policy{
        id: "pol_1", role: "editor", resource: "post",
        actions: ["delete"], condition: "is_owner"
      })

      subject = %{id: "user:anne", role: "editor"}
      resource = %{owner_id: "user:anne"}
      assert Evaluator.can?(store, subject, "delete", "post", resource)
    end

    test "policy with failing condition returns false", %{store: store} do
      :ok = Store.put_condition(store, %Condition{
        name: "is_owner",
        op: :eq,
        field: "subject.id",
        value: %{ref: "resource.owner_id"}
      })
      :ok = Store.put_policy(store, %Policy{
        id: "pol_1", role: "editor", resource: "post",
        actions: ["delete"], condition: "is_owner"
      })

      subject = %{id: "user:anne", role: "editor"}
      resource = %{owner_id: "user:bob"}
      refute Evaluator.can?(store, subject, "delete", "post", resource)
    end

    test "unconditional policy grants access regardless of resource context", %{store: store} do
      :ok = Store.put_policy(store, %Policy{
        id: "pol_1", role: "editor", resource: "post",
        actions: ["read"], condition: nil
      })

      subject = %{id: "user:anne", role: "editor"}
      assert Evaluator.can?(store, subject, "read", "post")
      assert Evaluator.can?(store, subject, "read", "post", %{owner_id: "someone_else"})
    end
  end
end
