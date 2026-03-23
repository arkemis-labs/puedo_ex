defmodule Puedo.Types.Snapshot do
  alias Puedo.Types.{Role, Resource, Policy, Condition}

  @type t :: %__MODULE__{
          schema_version: pos_integer(),
          version: non_neg_integer(),
          updated_at: DateTime.t() | nil,
          roles: %{String.t() => Role.t()},
          resources: %{String.t() => Resource.t()},
          policies: [Policy.t()],
          conditions: %{String.t() => Condition.t()}
        }

  defstruct schema_version: 1,
            version: 0,
            updated_at: nil,
            roles: %{},
            resources: %{},
            policies: [],
            conditions: %{}
end
