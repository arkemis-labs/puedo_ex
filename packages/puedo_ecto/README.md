# PuedoEcto

Ecto-backed persistence for [Puedo](../puedo/README.md). Stores roles, resources, policies, and conditions in a PostgreSQL database and loads them into Puedo's ETS cache at runtime.

## Installation

```elixir
def deps do
  [
    {:puedo, "~> 0.1.0"},
    {:puedo_ecto, "~> 0.1.0"}
  ]
end
```

`puedo_ecto` requires only `ecto`. Add `ecto_sql` and your database adapter separately in your application.

## Setup

### 1. Add the migrations path to your repo config

```text
config :my_app, MyApp.MyRepo,
  migrations_path: ["your/migration/path", "deps/puedo_ecto/lib/priv/repo/migrations"]
```

Then run:

```bash
mix ecto.migrate
```

The migration creates all four tables: `puedo_roles`, `puedo_resources`, `puedo_conditions`, and `puedo_policies`.

If you are unsure about the path to write simply start a iex terminal using

```bash
iex -S mix
```

and run the command below to see where they are located

```bash
PuedoEcto.migrations_path
```

### 2. Start Puedo with the Ecto backend

```elixir
children = [
  MyApp.Repo,
  {Puedo.Supervisor, backend: {PuedoEcto.Backend, repo: MyApp.Repo}}
]
```

That's it. Puedo will call `load_snapshot/1` on startup and populate its ETS cache from the database.

## Usage

Use Puedo's API as normal — mutations go through the backend and are persisted automatically:

```elixir
Puedo.put_role(%Puedo.Types.Role{id: "viewer"})
Puedo.put_role(%Puedo.Types.Role{id: "editor", inherits: ["viewer"]})

Puedo.put_resource(%Puedo.Types.Resource{id: "post", actions: ["read", "create", "delete"]})

Puedo.put_policy(%Puedo.Types.Policy{
  id: "pol_1", role: "viewer", resource: "post", actions: ["read"]
})

Puedo.can?(%{role: "editor"}, "read", "post")  # => true (inherited from viewer)
```

### Conditional policies

```elixir
Puedo.put_condition(%Puedo.Types.Condition{
  name: "is_owner", op: :eq,
  field: "subject.id", value: %{ref: "resource.owner_id"}
})

Puedo.put_policy(%Puedo.Types.Policy{
  id: "pol_2", role: "editor", resource: "post",
  actions: ["delete"], condition: "is_owner"
})

Puedo.can?(%{id: "user:anne", role: "editor"}, "delete", "post", %{owner_id: "user:anne"})
# => true
```

## Schema reference

| Table | Primary key | Notes |
| --- | --- | --- |
| `puedo_roles` | `id` (string) | `inherits` is a string array of role ids |
| `puedo_resources` | `id` (string) | `actions` and `relations` are string arrays |
| `puedo_conditions` | `name` (string) | Leaf conditions use `field`/`value`; compound conditions use `rules` (json array) |
| `puedo_policies` | `id` (string) | `actions` must be a subset of `create read update delete`; `condition` is nullable |

## Compound conditions

Conditions can be nested. Leaf nodes use `field`/`value`; compound nodes use `op: :and | :or | :not` with `rules`:

```elixir
Puedo.put_condition(%Puedo.Types.Condition{
  name: "can_edit",
  op: :and,
  rules: [
    %Puedo.Types.Condition{name: "is_owner", op: :eq, field: "owner_id"},
    %Puedo.Types.Condition{name: "is_active", op: :eq, field: "status", value: %{"value" => "active"}}
  ]
})
```

`field` and `rules` are mutually exclusive — setting both is a changeset error.
