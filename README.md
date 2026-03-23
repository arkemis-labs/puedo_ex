# Puedo

A pluggable authorization engine for Elixir. Policy-based RBAC with conditions.

## Packages

| Package | Description | Status |
|---------|-------------|--------|
| [`puedo`](packages/puedo) | Core library. Types, evaluator, condition engine, in-memory backend. | In progress |
| `puedo_ecto` | Ecto/Postgres backend. | Planned |
| `puedo_phoenix` | Phoenix integration. Authorization plug, REST API. | Planned |

## Monorepo

This project uses [Workspace](https://hexdocs.pm/workspace) for monorepo management.

```bash
# Run a command across all packages
mix workspace.run -t test

# See the dependency graph
mix workspace.graph --show-status
```

## Architecture

- **Core library** (`puedo`) -- Pure Elixir, zero external dependencies. ETS-backed hot path for authorization checks with zero message passing.
- **Backend implementations** -- Separate packages implementing `Puedo.Backend` for different storage engines.
