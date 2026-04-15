defmodule PuedoEcto.Schema.RoleTest do
  use ExUnit.Case, async: true

  alias PuedoEcto.Schema.Role

  test "valid with id only" do
    assert %{valid?: true} = Role.changeset(%Role{}, %{id: "admin"})
  end

  test "valid with inherits" do
    assert %{valid?: true} = Role.changeset(%Role{}, %{id: "editor", inherits: ["viewer"]})
  end

  test "invalid without id" do
    cs = Role.changeset(%Role{}, %{})
    assert %{valid?: false} = cs
    assert cs.errors[:id]
  end
end
