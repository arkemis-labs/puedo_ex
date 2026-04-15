defmodule PuedoEcto.BackendTest do
  use ExUnit.Case, async: true

  alias PuedoEcto.{Backend, FakeRepo}
  alias Puedo.Types.{Role, Resource, Policy, Condition, Snapshot}

  setup do
    FakeRepo.reset()
    {:ok, state} = Backend.init(repo: FakeRepo)
    %{state: state}
  end

  # ---- init ----------------------------------------------------------------

  describe "init/1" do
    test "returns error when repo is missing" do
      assert {:error, :missing_repo} = Backend.init([])
    end
  end

  # ---- Role ----------------------------------------------------------------

  describe "role round-trip" do
    test "put then load returns the same role", %{state: state} do
      role = %Role{id: "admin", inherits: []}
      {:ok, state} = Backend.put_role(state, role)
      assert {:ok, %Snapshot{roles: %{"admin" => ^role}}} = Backend.load_snapshot(state)
    end

    test "inherits list is preserved", %{state: state} do
      role = %Role{id: "editor", inherits: ["viewer", "commenter"]}
      {:ok, state} = Backend.put_role(state, role)
      assert {:ok, %Snapshot{roles: roles}} = Backend.load_snapshot(state)
      assert roles["editor"].inherits == ["viewer", "commenter"]
    end

    test "upsert replaces existing role", %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: ["viewer"]})
      assert {:ok, %Snapshot{roles: roles}} = Backend.load_snapshot(state)
      assert roles["admin"].inherits == ["viewer"]
      assert map_size(roles) == 1
    end

    test "multiple roles are all loaded", %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.put_role(state, %Role{id: "viewer", inherits: []})
      assert {:ok, %Snapshot{roles: roles}} = Backend.load_snapshot(state)
      assert map_size(roles) == 2
    end
  end

  describe "delete_role/2" do
    test "removed role is absent from snapshot", %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.delete_role(state, "admin")
      assert {:ok, %Snapshot{roles: roles}} = Backend.load_snapshot(state)
      refute Map.has_key?(roles, "admin")
    end

    test "deleting non-existent id is a no-op", %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.delete_role(state, "ghost")
      assert {:ok, %Snapshot{roles: roles}} = Backend.load_snapshot(state)
      assert map_size(roles) == 1
    end
  end

  # ---- Resource ------------------------------------------------------------

  describe "resource round-trip" do
    test "put then load returns the same resource", %{state: state} do
      resource = %Resource{id: "document", actions: ["read", "write"], relations: ["owner"]}
      {:ok, state} = Backend.put_resource(state, resource)
      assert {:ok, %Snapshot{resources: resources}} = Backend.load_snapshot(state)
      assert resources["document"].actions == ["read", "write"]
      assert resources["document"].relations == ["owner"]
    end

    test "upsert replaces existing resource", %{state: state} do
      {:ok, state} = Backend.put_resource(state, %Resource{id: "doc", actions: ["read"]})
      {:ok, state} = Backend.put_resource(state, %Resource{id: "doc", actions: ["read", "write"]})
      assert {:ok, %Snapshot{resources: resources}} = Backend.load_snapshot(state)
      assert resources["doc"].actions == ["read", "write"]
      assert map_size(resources) == 1
    end
  end

  # ---- Policy --------------------------------------------------------------

  describe "policy round-trip" do
    setup %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.put_resource(state, %Resource{id: "doc", actions: []})
      %{state: state}
    end

    test "put then load returns the same policy", %{state: state} do
      policy = %Policy{
        id: "p1",
        role: "admin",
        resource: "doc",
        actions: ["read"],
        condition: nil
      }

      {:ok, state} = Backend.put_policy(state, policy)
      assert {:ok, %Snapshot{policies: [loaded]}} = Backend.load_snapshot(state)
      assert loaded.id == "p1"
      assert loaded.role == "admin"
      assert loaded.resource == "doc"
      assert loaded.condition == nil
    end

    test "actions are preserved as strings", %{state: state} do
      policy = %Policy{
        id: "p1",
        role: "admin",
        resource: "doc",
        actions: ["create", "read", "update", "delete"],
        condition: nil
      }

      {:ok, state} = Backend.put_policy(state, policy)
      assert {:ok, %Snapshot{policies: [loaded]}} = Backend.load_snapshot(state)
      assert loaded.actions == ["create", "read", "update", "delete"]
    end

    test "policy with condition reference is preserved", %{state: state} do
      {:ok, state} =
        Backend.put_condition(state, %Condition{name: "is_owner", op: :eq, field: "owner_id"})

      policy = %Policy{
        id: "p1",
        role: "admin",
        resource: "doc",
        actions: ["write"],
        condition: "is_owner"
      }

      {:ok, state} = Backend.put_policy(state, policy)
      assert {:ok, %Snapshot{policies: [loaded]}} = Backend.load_snapshot(state)
      assert loaded.condition == "is_owner"
    end

    test "invalid actions are rejected", %{state: state} do
      policy = %Policy{id: "p1", role: "admin", resource: "doc", actions: ["fly"], condition: nil}
      assert {:error, _changeset} = Backend.put_policy(state, policy)
    end

    test "upsert replaces existing policy", %{state: state} do
      {:ok, state} =
        Backend.put_policy(state, %Policy{
          id: "p1",
          role: "admin",
          resource: "doc",
          actions: ["read"],
          condition: nil
        })

      {:ok, state} =
        Backend.put_policy(state, %Policy{
          id: "p1",
          role: "admin",
          resource: "doc",
          actions: ["read", "write"],
          condition: nil
        })

      assert {:ok, %Snapshot{policies: [loaded]}} = Backend.load_snapshot(state)
      assert loaded.actions == ["read", "write"]
    end
  end

  describe "delete_policy/2" do
    setup %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.put_resource(state, %Resource{id: "doc", actions: []})
      %{state: state}
    end

    test "removed policy is absent from snapshot", %{state: state} do
      {:ok, state} =
        Backend.put_policy(state, %Policy{
          id: "p1",
          role: "admin",
          resource: "doc",
          actions: ["read"],
          condition: nil
        })

      {:ok, state} = Backend.delete_policy(state, "p1")
      assert {:ok, %Snapshot{policies: []}} = Backend.load_snapshot(state)
    end
  end

  # ---- Condition -----------------------------------------------------------

  describe "condition round-trip" do
    test "leaf condition: op and field are preserved", %{state: state} do
      condition = %Condition{name: "is_owner", op: :eq, field: "owner_id", value: nil}
      {:ok, state} = Backend.put_condition(state, condition)
      assert {:ok, %Snapshot{conditions: conditions}} = Backend.load_snapshot(state)
      loaded = conditions["is_owner"]
      assert loaded.op == :eq
      assert loaded.field == "owner_id"
      assert loaded.rules == nil
    end

    test "leaf condition: value map is preserved", %{state: state} do
      condition = %Condition{
        name: "is_owner",
        op: :eq,
        field: "owner_id",
        value: %{"ref" => "user.id"}
      }

      {:ok, state} = Backend.put_condition(state, condition)
      assert {:ok, %Snapshot{conditions: conditions}} = Backend.load_snapshot(state)
      assert conditions["is_owner"].value == %{"ref" => "user.id"}
    end

    test "compound condition: rules are deserialized back to Condition structs", %{state: state} do
      condition = %Condition{
        name: "can_edit",
        op: :and,
        rules: [
          %Condition{name: "is_owner", op: :eq, field: "owner_id"},
          %Condition{name: "is_active", op: :eq, field: "status", value: %{"value" => "active"}}
        ]
      }

      {:ok, state} = Backend.put_condition(state, condition)
      assert {:ok, %Snapshot{conditions: conditions}} = Backend.load_snapshot(state)
      loaded = conditions["can_edit"]
      assert loaded.op == :and
      assert loaded.field == nil
      assert [r1, r2] = loaded.rules
      assert %Condition{name: "is_owner", op: :eq, field: "owner_id"} = r1
      assert %Condition{name: "is_active", op: :eq} = r2
    end

    test "all valid ops survive the round-trip", %{state: state} do
      ops = [:eq, :gt, :lt, :gte, :lte, :in]

      state =
        Enum.reduce(ops, state, fn op, acc ->
          {:ok, acc} =
            Backend.put_condition(acc, %Condition{name: "cond_#{op}", op: op, field: "x"})

          acc
        end)

      assert {:ok, %Snapshot{conditions: conditions}} = Backend.load_snapshot(state)

      for op <- ops do
        assert conditions["cond_#{op}"].op == op
      end
    end

    test "invalid op is rejected", %{state: state} do
      condition = %Condition{name: "bad", op: :unknown, field: "x"}
      assert {:error, _changeset} = Backend.put_condition(state, condition)
    end

    test "upsert replaces existing condition", %{state: state} do
      {:ok, state} =
        Backend.put_condition(state, %Condition{name: "cond", op: :eq, field: "x"})

      {:ok, state} =
        Backend.put_condition(state, %Condition{name: "cond", op: :gt, field: "y"})

      assert {:ok, %Snapshot{conditions: conditions}} = Backend.load_snapshot(state)
      assert conditions["cond"].op == :gt
      assert conditions["cond"].field == "y"
      assert map_size(conditions) == 1
    end
  end

  describe "delete_condition/2" do
    test "removed condition is absent from snapshot", %{state: state} do
      {:ok, state} =
        Backend.put_condition(state, %Condition{name: "is_owner", op: :eq, field: "owner_id"})

      {:ok, state} = Backend.delete_condition(state, "is_owner")
      assert {:ok, %Snapshot{conditions: conditions}} = Backend.load_snapshot(state)
      refute Map.has_key?(conditions, "is_owner")
    end
  end

  # ---- Snapshot completeness -----------------------------------------------

  describe "load_snapshot/1" do
    test "empty repo returns empty snapshot", %{state: state} do
      assert {:ok, %Snapshot{roles: r, resources: res, policies: p, conditions: c}} =
               Backend.load_snapshot(state)

      assert r == %{}
      assert res == %{}
      assert p == []
      assert c == %{}
    end

    test "snapshot contains all stored entities", %{state: state} do
      {:ok, state} = Backend.put_role(state, %Role{id: "admin", inherits: []})
      {:ok, state} = Backend.put_resource(state, %Resource{id: "doc", actions: []})

      {:ok, state} =
        Backend.put_condition(state, %Condition{name: "cond", op: :eq, field: "x"})

      {:ok, state} =
        Backend.put_policy(state, %Policy{
          id: "p1",
          role: "admin",
          resource: "doc",
          actions: ["read"],
          condition: nil
        })

      assert {:ok, snap} = Backend.load_snapshot(state)
      assert map_size(snap.roles) == 1
      assert map_size(snap.resources) == 1
      assert length(snap.policies) == 1
      assert map_size(snap.conditions) == 1
    end
  end
end
