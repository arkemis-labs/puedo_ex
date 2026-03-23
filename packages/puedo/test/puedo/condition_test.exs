defmodule Puedo.ConditionTest do
  use ExUnit.Case, async: true

  alias Puedo.Condition
  alias Puedo.Types.Condition, as: ConditionType

  describe "eq" do
    test "literal value matches" do
      condition = %ConditionType{name: "check", op: :eq, field: "subject.role", value: "admin"}
      context = %{subject: %{role: "admin"}, resource: %{}}
      assert Condition.evaluate(condition, context)
    end

    test "literal value does not match" do
      condition = %ConditionType{name: "check", op: :eq, field: "subject.role", value: "admin"}
      context = %{subject: %{role: "viewer"}, resource: %{}}
      refute Condition.evaluate(condition, context)
    end

    test "ref value matches" do
      condition = %ConditionType{
        name: "is_owner",
        op: :eq,
        field: "subject.id",
        value: %{ref: "resource.owner_id"}
      }

      context = %{subject: %{id: "user:anne"}, resource: %{owner_id: "user:anne"}}
      assert Condition.evaluate(condition, context)
    end

    test "ref value does not match" do
      condition = %ConditionType{
        name: "is_owner",
        op: :eq,
        field: "subject.id",
        value: %{ref: "resource.owner_id"}
      }

      context = %{subject: %{id: "user:anne"}, resource: %{owner_id: "user:bob"}}
      refute Condition.evaluate(condition, context)
    end
  end

  describe "gt / lt / gte / lte" do
    test "gt" do
      condition = %ConditionType{name: "check", op: :gt, field: "subject.age", value: 18}
      assert Condition.evaluate(condition, %{subject: %{age: 21}, resource: %{}})
      refute Condition.evaluate(condition, %{subject: %{age: 18}, resource: %{}})
    end

    test "lt" do
      condition = %ConditionType{name: "check", op: :lt, field: "subject.age", value: 18}
      assert Condition.evaluate(condition, %{subject: %{age: 10}, resource: %{}})
      refute Condition.evaluate(condition, %{subject: %{age: 18}, resource: %{}})
    end

    test "gte" do
      condition = %ConditionType{name: "check", op: :gte, field: "subject.age", value: 18}
      assert Condition.evaluate(condition, %{subject: %{age: 18}, resource: %{}})
      refute Condition.evaluate(condition, %{subject: %{age: 17}, resource: %{}})
    end

    test "lte" do
      condition = %ConditionType{name: "check", op: :lte, field: "subject.age", value: 18}
      assert Condition.evaluate(condition, %{subject: %{age: 18}, resource: %{}})
      refute Condition.evaluate(condition, %{subject: %{age: 19}, resource: %{}})
    end
  end

  describe "in" do
    test "in returns true when field value is in list" do
      condition = %ConditionType{
        name: "check",
        op: :in,
        field: "subject.role",
        value: ["admin", "editor"]
      }

      context = %{subject: %{role: "admin"}, resource: %{}}
      assert Condition.evaluate(condition, context)
    end

    test "in returns false when field value is not in list" do
      condition = %ConditionType{
        name: "check",
        op: :in,
        field: "subject.role",
        value: ["admin", "editor"]
      }

      context = %{subject: %{role: "viewer"}, resource: %{}}
      refute Condition.evaluate(condition, context)
    end
  end

  describe "compound: and" do
    test "returns true when all rules pass" do
      condition = %ConditionType{
        name: "both",
        op: :and,
        rules: [
          %ConditionType{name: "r1", op: :eq, field: "subject.role", value: "editor"},
          %ConditionType{
            name: "r2",
            op: :eq,
            field: "subject.id",
            value: %{ref: "resource.owner_id"}
          }
        ]
      }

      context = %{subject: %{id: "user:anne", role: "editor"}, resource: %{owner_id: "user:anne"}}
      assert Condition.evaluate(condition, context)
    end

    test "returns false when one rule fails" do
      condition = %ConditionType{
        name: "both",
        op: :and,
        rules: [
          %ConditionType{name: "r1", op: :eq, field: "subject.role", value: "editor"},
          %ConditionType{
            name: "r2",
            op: :eq,
            field: "subject.id",
            value: %{ref: "resource.owner_id"}
          }
        ]
      }

      context = %{subject: %{id: "user:anne", role: "editor"}, resource: %{owner_id: "user:bob"}}
      refute Condition.evaluate(condition, context)
    end
  end

  describe "compound: or" do
    test "returns true when at least one rule passes" do
      condition = %ConditionType{
        name: "either",
        op: :or,
        rules: [
          %ConditionType{name: "r1", op: :eq, field: "subject.role", value: "admin"},
          %ConditionType{
            name: "r2",
            op: :eq,
            field: "subject.id",
            value: %{ref: "resource.owner_id"}
          }
        ]
      }

      context = %{subject: %{id: "user:anne", role: "editor"}, resource: %{owner_id: "user:anne"}}
      assert Condition.evaluate(condition, context)
    end

    test "returns false when no rules pass" do
      condition = %ConditionType{
        name: "either",
        op: :or,
        rules: [
          %ConditionType{name: "r1", op: :eq, field: "subject.role", value: "admin"},
          %ConditionType{
            name: "r2",
            op: :eq,
            field: "subject.id",
            value: %{ref: "resource.owner_id"}
          }
        ]
      }

      context = %{subject: %{id: "user:anne", role: "viewer"}, resource: %{owner_id: "user:bob"}}
      refute Condition.evaluate(condition, context)
    end
  end

  describe "compound: not" do
    test "negates a passing rule" do
      condition = %ConditionType{
        name: "not_owner",
        op: :not,
        rules: [
          %ConditionType{
            name: "r1",
            op: :eq,
            field: "subject.id",
            value: %{ref: "resource.owner_id"}
          }
        ]
      }

      context = %{subject: %{id: "user:anne"}, resource: %{owner_id: "user:anne"}}
      refute Condition.evaluate(condition, context)
    end

    test "negates a failing rule" do
      condition = %ConditionType{
        name: "not_owner",
        op: :not,
        rules: [
          %ConditionType{
            name: "r1",
            op: :eq,
            field: "subject.id",
            value: %{ref: "resource.owner_id"}
          }
        ]
      }

      context = %{subject: %{id: "user:anne"}, resource: %{owner_id: "user:bob"}}
      assert Condition.evaluate(condition, context)
    end
  end

  describe "field resolution" do
    test "resolves nested string-keyed fields" do
      condition = %ConditionType{
        name: "check",
        op: :eq,
        field: "subject.address.city",
        value: "Rome"
      }

      context = %{subject: %{address: %{city: "Rome"}}, resource: %{}}
      assert Condition.evaluate(condition, context)
    end
  end
end
