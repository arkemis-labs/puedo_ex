defmodule Puedo.Types.Policy do
  @type t :: %__MODULE__{
          id: String.t(),
          role: String.t(),
          resource: String.t(),
          actions: [String.t()],
          condition: String.t() | nil
        }

  @enforce_keys [:id, :role, :resource, :actions]
  defstruct [:id, :role, :resource, :condition, actions: []]
end
