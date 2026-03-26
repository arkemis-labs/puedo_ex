defmodule PuedoEcto.Schema.Policy do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:id, :string, autogenerate: false}
  schema "puedo_policies" do
    field :role, :string
    field :resource, :string
    field :actions, {:array, :string}, default: []
    field :condition, :string
    timestamps()
  end

  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [:id, :role, :resource, :actions, :condition])
    |> validate_required([:id, :role, :resource, :actions])
    |> foreign_key_constraint(:role, name: :puedo_policies_role_fkey)
    |> foreign_key_constraint(:resource, name: :puedo_policies_resource_fkey)
    |> foreign_key_constraint(:condition, name: :puedo_policies_condition_fkey)
  end
end
