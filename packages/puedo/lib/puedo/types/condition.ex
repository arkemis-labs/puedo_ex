defmodule Puedo.Types.Condition do
  @type op :: :eq | :gt | :lt | :gte | :lte | :in | :and | :or | :not

  @type value :: term() | %{ref: String.t()}

  @type t :: %__MODULE__{
          name: String.t(),
          op: op(),
          field: String.t() | nil,
          value: value() | nil,
          rules: [t()] | nil
        }

  @enforce_keys [:name, :op]
  defstruct [:name, :op, :field, :value, :rules]
end
