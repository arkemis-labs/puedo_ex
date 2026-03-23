# Puedo

Core authorization library. Policy-based RBAC with conditions, powered by ETS for fast permission checks.

## Installation

```elixir
def deps do
  [
    {:puedo, "~> 0.1.0"}
  ]
end
```

## Quick Start

Add Puedo to your supervision tree:

```elixir
children = [
  {Puedo.Supervisor, backend: {Puedo.Backend.Memory, []}}
]
```

Define roles, resources, and policies:

```elixir
Puedo.put_role(%Puedo.Types.Role{id: "viewer"})
Puedo.put_role(%Puedo.Types.Role{id: "editor", inherits: ["viewer"]})

Puedo.put_resource(%Puedo.Types.Resource{id: "post", actions: ["read", "create", "delete"]})

Puedo.put_policy(%Puedo.Types.Policy{id: "pol_1", role: "viewer", resource: "post", actions: ["read"]})
Puedo.put_policy(%Puedo.Types.Policy{id: "pol_2", role: "editor", resource: "post", actions: ["create"]})
```

Check permissions:

```elixir
subject = %{id: "user:anne", role: "editor"}

Puedo.can?(subject, "read", "post")    # => true (inherited from viewer)
Puedo.can?(subject, "create", "post")  # => true
Puedo.can?(subject, "delete", "post")  # => false
```

### Conditional policies

```elixir
Puedo.put_condition(%Puedo.Types.Condition{
  name: "is_owner", op: :eq,
  field: "subject.id", value: %{ref: "resource.owner_id"}
})

Puedo.put_policy(%Puedo.Types.Policy{
  id: "pol_3", role: "editor", resource: "post",
  actions: ["delete"], condition: "is_owner"
})

Puedo.can?(subject, "delete", "post", %{owner_id: "user:anne"})  # => true
Puedo.can?(subject, "delete", "post", %{owner_id: "user:bob"})   # => false
```
