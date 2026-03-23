defmodule Puedo.Store do
  use GenServer

  @type backend :: {module(), term()}

  @type state :: %{
          backend: backend(),
          table: :ets.table(),
          version: non_neg_integer()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec put_role(GenServer.server(), Role.t()) :: :ok | {:error, term()}
  def put_role(server, role) do
    GenServer.call(server, {:put_role, role})
  end

  @spec put_resource(GenServer.server(), Resource.t()) :: :ok | {:error, term()}
  def put_resource(server, resource) do
    GenServer.call(server, {:put_resource, resource})
  end

  @spec put_policy(GenServer.server(), Policy.t()) :: :ok | {:error, term()}
  def put_policy(server, policy) do
    GenServer.call(server, {:put_policy, policy})
  end

  @spec put_condition(GenServer.server(), Condition.t()) :: :ok | {:error, term()}
  def put_condition(server, condition) do
    GenServer.call(server, {:put_condition, condition})
  end

  @spec delete_role(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_role(server, role_id) do
    GenServer.call(server, {:delete_role, role_id})
  end

  @spec delete_policy(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_policy(server, policy_id) do
    GenServer.call(server, {:delete_policy, policy_id})
  end

  @spec delete_condition(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_condition(server, condition_id) do
    GenServer.call(server, {:delete_condition, condition_id})
  end

  @spec get_role(GenServer.server(), String.t()) :: Role.t() | nil
  def get_role(server, id) do
    GenServer.call(server, {:get_role, id})
  end

  @spec get_resource(GenServer.server(), String.t()) :: Resource.t() | nil
  def get_resource(server, id) do
    GenServer.call(server, {:get_resource, id})
  end

  @spec get_condition(GenServer.server(), String.t()) :: Condition.t() | nil
  def get_condition(server, name) do
    GenServer.call(server, {:get_condition, name})
  end

  @spec list_roles(GenServer.server()) :: [Role.t()]
  def list_roles(server) do
    GenServer.call(server, {:list_roles})
  end

  @spec list_resources(GenServer.server()) :: [Resource.t()]
  def list_resources(server) do
    GenServer.call(server, {:list_resources})
  end

  @spec list_policies(GenServer.server()) :: [Policy.t()]
  def list_policies(server) do
    GenServer.call(server, {:list_policies})
  end

  @spec list_conditions(GenServer.server()) :: [Condition.t()]
  def list_conditions(server) do
    GenServer.call(server, {:list_conditions})
  end

  @spec snapshot(GenServer.server()) :: Snapshot.t()
  def snapshot(server) do
    GenServer.call(server, {:snapshot})
  end

  @spec version(GenServer.server()) :: non_neg_integer()
  def version(server) do
    GenServer.call(server, {:version})
  end

  @impl true
  def init(opts) do
    {backend_module, backend_opts} = Keyword.fetch!(opts, :backend)
    {:ok, backend_state} = backend_module.init(backend_opts)
    {:ok, snapshot} = backend_module.load_snapshot(backend_state)

    table = :ets.new(:puedo_store, [:set, :public, read_concurrency: true])
    populate_ets(table, snapshot)

    {:ok, %{backend: {backend_module, backend_state}, table: table, version: snapshot.version}}
  end

  @impl true
  def handle_call({:put_role, role}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.put_role(backend_state, role)
    :ets.insert(state.table, {{:role, role.id}, role})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:put_resource, resource}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.put_resource(backend_state, resource)
    :ets.insert(state.table, {{:resource, resource.id}, resource})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:put_policy, policy}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.put_policy(backend_state, policy)
    :ets.insert(state.table, {{:policy, policy.id}, policy})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:put_condition, condition}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.put_condition(backend_state, condition)
    :ets.insert(state.table, {{:condition, condition.name}, condition})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:delete_role, id}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.delete_role(backend_state, id)
    :ets.delete(state.table, {:role, id})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:delete_policy, id}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.delete_policy(backend_state, id)
    :ets.delete(state.table, {:policy, id})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:delete_condition, name}, _from, state) do
    {backend_module, backend_state} = state.backend
    {:ok, backend_state} = backend_module.delete_condition(backend_state, name)
    :ets.delete(state.table, {:condition, name})
    {:reply, :ok, %{state | backend: {backend_module, backend_state}, version: state.version + 1}}
  end

  @impl true
  def handle_call({:get_role, id}, _from, state) do
    {:reply, ets_lookup(state.table, {:role, id}), state}
  end

  @impl true
  def handle_call({:get_resource, id}, _from, state) do
    {:reply, ets_lookup(state.table, {:resource, id}), state}
  end

  @impl true
  def handle_call({:get_condition, name}, _from, state) do
    {:reply, ets_lookup(state.table, {:condition, name}), state}
  end

  @impl true
  def handle_call({:list_roles}, _from, state) do
    result =
      :ets.match_object(state.table, {{:role, :_}, :_})
      |> Enum.map(&elem(&1, 1))

    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_resources}, _from, state) do
    result =
      :ets.match_object(state.table, {{:resource, :_}, :_})
      |> Enum.map(&elem(&1, 1))

    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_policies}, _from, state) do
    result =
      :ets.match_object(state.table, {{:policy, :_}, :_})
      |> Enum.map(&elem(&1, 1))

    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_conditions}, _from, state) do
    result =
      :ets.match_object(state.table, {{:condition, :_}, :_})
      |> Enum.map(&elem(&1, 1))

    {:reply, result, state}
  end

  @impl true
  def handle_call({:snapshot}, _from, state) do
    roles =
      :ets.match_object(state.table, {{:role, :_}, :_})
      |> Map.new(fn {{:role, id}, role} -> {id, role} end)

    resources =
      :ets.match_object(state.table, {{:resource, :_}, :_})
      |> Map.new(fn {{:resource, id}, resource} -> {id, resource} end)

    policies =
      :ets.match_object(state.table, {{:policy, :_}, :_})
      |> Enum.map(&elem(&1, 1))

    conditions =
      :ets.match_object(state.table, {{:condition, :_}, :_})
      |> Map.new(fn {{:condition, name}, condition} -> {name, condition} end)

    snapshot = %Puedo.Types.Snapshot{
      version: state.version,
      roles: roles,
      resources: resources,
      policies: policies,
      conditions: conditions
    }

    {:reply, snapshot, state}
  end

  @impl true
  def handle_call({:version}, _from, state) do
    {:reply, state.version, state}
  end

  defp ets_lookup(table, key) do
    case :ets.lookup(table, key) do
      [{_key, value}] -> value
      [] -> nil
    end
  end

  defp populate_ets(table, snapshot) do
    for {id, role} <- snapshot.roles, do: :ets.insert(table, {{:role, id}, role})
    for {id, resource} <- snapshot.resources, do: :ets.insert(table, {{:resource, id}, resource})
    for policy <- snapshot.policies, do: :ets.insert(table, {{:policy, policy.id}, policy})

    for {name, condition} <- snapshot.conditions,
        do: :ets.insert(table, {{:condition, name}, condition})

    :ets.insert(table, {:meta, snapshot.version, snapshot.updated_at, snapshot.schema_version})
    :ok
  end
end
