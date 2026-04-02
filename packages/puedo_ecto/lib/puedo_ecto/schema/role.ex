defmodule PuedoEcto.Schema.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "puedo_roles" do
    field(:inherits, {:array, :string}, default: [])
    timestamps()
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:id, :inherits])
    |> validate_required([:id])
  end
end
