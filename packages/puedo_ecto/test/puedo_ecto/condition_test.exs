defmodule PuedoEcto.Schema.ConditionTest do
  use ExUnit.Case, async: true

  alias PuedoEcto.Schema.Condition, as: ConditionSchema
  alias Puedo.Condition
  alias Puedo.Types.Condition, as: ConditionType

  @tag :this
  test "valid leaf condition" do
    condition = %ConditionType{name: "check", op: :eq, field: "subject.role", value: "admin"}
    context = %{subject: %{role: "admin"}, resource: %{}}
    assert Condition.evaluate(condition, context)

    cs =
      ConditionSchema.changeset(%ConditionSchema{}, %{
        name: "is_owner",
        op: :eq,
        field: "owner_id"
      })

    assert %{valid?: true} = cs
  end

  test "valid compound condition" do
    cs =
      ConditionSchema.changeset(%ConditionSchema{}, %{
        name: "can_edit",
        op: :and,
        rules: [%{"name" => "x", "op" => "eq"}]
      })

    assert %{valid?: true} = cs
  end

  test "invalid without name" do
    cs = ConditionSchema.changeset(%ConditionSchema{}, %{op: :eq})
    assert cs.errors[:name]
  end

  test "invalid without op" do
    cs = ConditionSchema.changeset(%ConditionSchema{}, %{name: "x"})
    assert cs.errors[:op]
  end

  test "invalid with unknown op" do
    cs = ConditionSchema.changeset(%ConditionSchema{}, %{name: "x", op: :unknown})
    assert %{valid?: false} = cs
    assert cs.errors[:op]
  end

  test "invalid when both field and rules are set" do
    cs =
      ConditionSchema.changeset(%ConditionSchema{}, %{
        name: "x",
        op: :and,
        field: "some_field",
        rules: [%{"name" => "y", "op" => "eq"}]
      })

    assert %{valid?: false} = cs
    assert cs.errors[:rules]
  end

  test "valid with only field" do
    cs = ConditionSchema.changeset(%ConditionSchema{}, %{name: "x", op: :eq, field: "owner_id"})
    assert %{valid?: true} = cs
  end

  test "valid with only rules" do
    cs = ConditionSchema.changeset(%ConditionSchema{}, %{name: "x", op: :and, rules: []})
    assert %{valid?: true} = cs
  end
end
