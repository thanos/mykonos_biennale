defmodule MykonosBiennale.Repo.Migrations.CreateEntityMedia do
  use Ecto.Migration

  def change do
    create table(:entity_media) do
      add :entity_id, references(:entities, on_delete: :delete_all), null: false
      add :media_id, references(:media, on_delete: :delete_all), null: false
      add :position, :integer, default: 0, null: false
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:entity_media, [:entity_id])
    create index(:entity_media, [:media_id])
    create unique_index(:entity_media, [:entity_id, :media_id])
    create index(:entity_media, [:entity_id, :position])
  end
end
