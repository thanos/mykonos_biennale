defmodule MykonosBiennale.Repo.Migrations.CreateEntitiesAndRelationships do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :identity, :string
      add :type, :string
      add :slug, :string
      add :visible, :boolean, default: false
      add :fields, :map

      timestamps(type: :utc_datetime)
    end

    create table(:relationships) do
      add :name, :string
      add :slug, :string
      add :fields, :map
      add :subject_id, references(:entities, on_delete: :nothing)
      add :object_id, references(:entities, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:relationships, [:subject_id])
    create index(:relationships, [:object_id])

    create unique_index(:relationships, [:subject_id, :slug, :object_id],
             name: :relationship_index
           )
  end
end
