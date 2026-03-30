defmodule PuedoPostgres.Repo.Migrations.CreatePuedoTables do
  use Ecto.Migration

  def change do
    create table(:puedo_roles, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :inherits, {:array, :string}, default: [], null: false
      timestamps()
    end

    create table(:puedo_resources, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :actions, {:array, :string}, default: [], null: false
      add :relations, {:array, :string}, default: [], null: false
      timestamps()
    end

    create table(:puedo_conditions, primary_key: false) do
      add :name, :string, primary_key: true, null: false
      add :op, :string, null: false
      add :field, :string
      add :value, :map
      add :rules, {:array, :map}
      timestamps()
    end

    create table(:puedo_policies, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :role, references(:puedo_roles, type: :string, on_delete: :delete_all), null: false
      add :resource, references(:puedo_resources, type: :string, on_delete: :delete_all), null: false
      add :actions, {:array, :string}, default: [], null: false
      add :condition, references(:puedo_conditions, column: :name, type: :string, on_delete: :nilify_all)
      timestamps()
    end

    create index(:puedo_policies, [:role])
    create index(:puedo_policies, [:resource])
    create index(:puedo_policies, [:condition])
  end
end
