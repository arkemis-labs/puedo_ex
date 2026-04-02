defmodule PuedoEcto.Schema.PolicyTest do
  use ExUnit.Case, async: true

  alias PuedoEcto.Schema.Policy

  @valid %{id: "p1", role: "admin", resource: "document", actions: ["read"]}

  test "valid with required fields" do
    assert %{valid?: true} = Policy.changeset(%Policy{}, @valid)
  end

  test "valid with condition" do
    assert %{valid?: true} =
             Policy.changeset(%Policy{}, Map.put(@valid, :condition, "is_owner"))
  end

  test "valid with all crud actions" do
    cs =
      Policy.changeset(
        %Policy{},
        Map.put(@valid, :actions, ["create", "read", "update", "delete"])
      )

    assert %{valid?: true} = cs
  end

  test "invalid without id" do
    cs = Policy.changeset(%Policy{}, Map.delete(@valid, :id))
    assert cs.errors[:id]
  end

  test "invalid without role" do
    cs = Policy.changeset(%Policy{}, Map.delete(@valid, :role))
    assert cs.errors[:role]
  end

  test "invalid without resource" do
    cs = Policy.changeset(%Policy{}, Map.delete(@valid, :resource))
    assert cs.errors[:resource]
  end

  test "invalid without actions" do
    cs = Policy.changeset(%Policy{}, Map.delete(@valid, :actions))
    assert cs.errors[:actions]
  end

  test "condition is optional" do
    cs = Policy.changeset(%Policy{}, @valid)
    assert %{valid?: true} = cs
    assert is_nil(get_field(cs, :condition))
  end

  defp get_field(cs, key), do: Ecto.Changeset.get_field(cs, key)
end
