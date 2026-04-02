defmodule PuedoEcto.Schema.Condition do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:name, :string, autogenerate: false}
  schema "puedo_conditions" do
    field(:op, Ecto.Enum, values: [:eq, :gt, :lt, :gte, :lte, :in, :and, :or, :not])
    field(:field, :string)
    field(:value, :map)
    field(:rules, {:array, :map})
    timestamps()
  end

  def changeset(condition, attrs) do
    condition
    |> cast(attrs, [:name, :op, :field, :value, :rules])
    |> validate_required([:name, :op])
    |> validate_exclusive(:field, :rules)
  end

  # we can set only one of `field` or `rules` depending on whether this is a leaf or compound condition
  defp validate_exclusive(changeset, field_a, field_b) do
    a = get_field(changeset, field_a)
    b = get_field(changeset, field_b)

    if not is_nil(a) and not is_nil(b) do
      add_error(changeset, field_b, "cannot be set when #{field_a} is present")
    else
      changeset
    end
  end
end
