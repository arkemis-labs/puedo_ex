defmodule PuedoEcto.Schema.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "puedo_resources" do
    field :actions, {:array, :string}, default: []
    field :relations, {:array, :string}, default: []
    timestamps()
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:id, :actions, :relations])
    |> validate_required([:id])
  end
end
