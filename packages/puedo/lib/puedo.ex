defmodule Puedo do
  alias Puedo.{Store, Evaluator}
  alias Puedo.Types.{Role, Resource, Policy, Condition, Snapshot}

  @store Puedo.Store

  # Evaluation
  @spec can?(Evaluator.subject(), String.t(), String.t(), Evaluator.resource_context()) ::
          boolean()
  def can?(subject, action, resource, resource_context \\ %{}),
    do: Evaluator.can?(@store, subject, action, resource, resource_context)

  @spec put_role(Role.t()) :: :ok | {:error, term()}
  def put_role(role), do: Store.put_role(@store, role)

  @spec put_resource(Resource.t()) :: :ok | {:error, term()}
  def put_resource(resource), do: Store.put_resource(@store, resource)

  @spec put_policy(Policy.t()) :: :ok | {:error, term()}
  def put_policy(policy), do: Store.put_policy(@store, policy)

  @spec put_condition(Condition.t()) :: :ok | {:error, term()}
  def put_condition(condition), do: Store.put_condition(@store, condition)

  @spec delete_role(String.t()) :: :ok | {:error, term()}
  def delete_role(id), do: Store.delete_role(@store, id)

  @spec delete_policy(String.t()) :: :ok | {:error, term()}
  def delete_policy(id), do: Store.delete_policy(@store, id)

  @spec delete_condition(String.t()) :: :ok | {:error, term()}
  def delete_condition(name), do: Store.delete_condition(@store, name)

  @spec list_roles() :: [Role.t()]
  def list_roles, do: Store.list_roles(@store)

  @spec list_resources() :: [Resource.t()]
  def list_resources, do: Store.list_resources(@store)

  @spec list_policies() :: [Policy.t()]
  def list_policies, do: Store.list_policies(@store)

  @spec list_conditions() :: [Condition.t()]
  def list_conditions, do: Store.list_conditions(@store)

  @spec snapshot() :: Snapshot.t()
  def snapshot, do: Store.snapshot(@store)

  @spec version() :: non_neg_integer()
  def version, do: Store.version(@store)
end
