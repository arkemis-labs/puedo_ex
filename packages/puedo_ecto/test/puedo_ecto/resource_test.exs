defmodule PuedoEcto.Schema.ResourceTest do
  use ExUnit.Case, async: true

  alias PuedoEcto.Schema.Resource

  test "valid with id only" do
    assert %{valid?: true} = Resource.changeset(%Resource{}, %{id: "document"})
  end

  test "valid with actions and relations" do
    assert %{valid?: true} =
             Resource.changeset(%Resource{}, %{
               id: "document",
               actions: ["read", "write"],
               relations: ["owner"]
             })
  end

  test "invalid without id" do
    cs = Resource.changeset(%Resource{}, %{})
    assert %{valid?: false} = cs
    assert cs.errors[:id]
  end
end
