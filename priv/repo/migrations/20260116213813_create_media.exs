defmodule MykonosBiennale.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :caption, :text
      add :source_type, :string, null: false
      add :source_url, :string
      add :source_embed, :text
      add :source_path, :string
      add :mime_type, :string
      add :alt_text, :string
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:media, [:source_type])
  end
end
