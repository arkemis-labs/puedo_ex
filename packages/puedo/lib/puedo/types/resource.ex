defmodule Puedo.Types.Resource do
  @type t :: %__MODULE__{
          id: String.t(),
          actions: [String.t()],
          relations: [String.t()]
        }
  @enforce_keys [:id]
  defstruct [:id, actions: [], relations: []]
end
