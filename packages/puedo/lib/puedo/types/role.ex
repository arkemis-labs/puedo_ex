defmodule Puedo.Types.Role do
  @type t :: %__MODULE__{
          id: String.t(),
          inherits: [String.t()]
        }
  @enforce_keys [:id]
  defstruct [:id, inherits: []]
end
