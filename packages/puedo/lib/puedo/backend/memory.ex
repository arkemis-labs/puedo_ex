defmodule Puedo.Backend.Memory do
  @behaviour Puedo.Backend

  alias Puedo.Types.Snapshot

  @impl true
  def init(_opts) do
    {:ok, %{roles: %{}, resources: %{}, policies: %{}, conditions: %{}}}
  end

  @impl true
  def load_snapshot(state) do
    {:ok,
     %Snapshot{
       roles: state.roles,
       resources: state.resources,
       policies: Map.values(state.policies),
       conditions: state.conditions
     }}
  end

  @impl true
  def put_role(state, role) do
    {:ok, put_in(state, [:roles, role.id], role)}
  end

  @impl true
  def put_resource(state, resource) do
    {:ok, put_in(state, [:resources, resource.id], resource)}
  end

  @impl true
  def put_policy(state, policy) do
    {:ok, put_in(state, [:policies, policy.id], policy)}
  end

  @impl true
  def put_condition(state, condition) do
    {:ok, put_in(state, [:conditions, condition.name], condition)}
  end

  @impl true
  def delete_role(state, id) do
    {:ok, %{state | roles: Map.delete(state.roles, id)}}
  end

  @impl true
  def delete_policy(state, id) do
    {:ok, %{state | policies: Map.delete(state.policies, id)}}
  end

  @impl true
  def delete_condition(state, name) do
    {:ok, %{state | conditions: Map.delete(state.conditions, name)}}
  end
  
  @impl true
  def delete_resource(state, name) do
    {:ok, %{state | resources: Map.delete(state.resources, name)}}
  end
end
