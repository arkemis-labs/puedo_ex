defmodule Puedo.Condition do
  alias Puedo.Types.Condition, as: ConditionType

  @type context :: %{subject: map(), resource: map()}

  @spec evaluate(ConditionType.t(), context()) :: boolean()
  def evaluate(%ConditionType{op: :eq, field: field, value: value}, context),
    do: resolve_field(field, context) == resolve_value(value, context)

  def evaluate(%ConditionType{op: :lt, field: field, value: value}, context),
    do: resolve_field(field, context) < resolve_value(value, context)

  def evaluate(%ConditionType{op: :lte, field: field, value: value}, context),
    do: resolve_field(field, context) <= resolve_value(value, context)

  def evaluate(%ConditionType{op: :gt, field: field, value: value}, context),
    do: resolve_field(field, context) > resolve_value(value, context)

  def evaluate(%ConditionType{op: :gte, field: field, value: value}, context),
    do: resolve_field(field, context) >= resolve_value(value, context)

  def evaluate(%ConditionType{op: :in, field: field, value: value}, context),
    do: resolve_value(value, context) |> Enum.member?(resolve_field(field, context))

  def evaluate(%ConditionType{op: :or, rules: rules}, context),
    do: Enum.any?(rules, &evaluate(&1, context))

  def evaluate(%ConditionType{op: :and, rules: rules}, context),
    do: Enum.all?(rules, &evaluate(&1, context))

  def evaluate(%ConditionType{op: :not, rules: rules}, context),
    do: not Enum.any?(rules, &evaluate(&1, context))

  defp resolve_field(field, context) do
    field
    |> String.split(".")
    |> Enum.reduce(context, fn key, acc ->
      Map.get(acc || %{}, String.to_existing_atom(key))
    end)
  end

  defp resolve_value(%{ref: ref}, context), do: resolve_field(ref, context)
  defp resolve_value(value, _context), do: value
end
