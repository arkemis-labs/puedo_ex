defmodule Puedo.Backend do
  alias Puedo.Types.{Role, Resource, Policy, Condition, Snapshot}

  @type state :: term()

  @callback init(opts :: keyword()) :: {:ok, state()} | {:error, term()}
  @callback load_snapshot(state()) :: {:ok, Snapshot.t()} | {:error, term()}
  @callback put_role(state(), Role.t()) :: {:ok, state()} | {:error, term()}
  @callback put_resource(state(), Resource.t()) :: {:ok, state()} | {:error, term()}
  @callback put_policy(state(), Policy.t()) :: {:ok, state()} | {:error, term()}
  @callback put_condition(state(), Condition.t()) :: {:ok, state()} | {:error, term()}
  @callback delete_role(state(), id :: String.t()) :: {:ok, state()} | {:error, term()}
  @callback delete_policy(state(), id :: String.t()) :: {:ok, state()} | {:error, term()}
  @callback delete_condition(state(), name :: String.t()) :: {:ok, state()} | {:error, term()}
end
