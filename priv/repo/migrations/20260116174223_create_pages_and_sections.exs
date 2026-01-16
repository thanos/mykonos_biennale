defmodule MykonosBiennale.Repo.Migrations.CreatePagesAndSections do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :position, :integer
      add :title, :string
      add :slug, :string
      add :description, :text
      add :template, :string
      add :content, :text
      add :visible, :boolean, default: false, null: false
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create table(:sections) do
      add :position, :integer
      add :title, :string
      add :slug, :string
      add :description, :text
      add :template, :string
      add :content, :text
      add :visible, :boolean, default: false, null: false
      add :metadata, :map
      add :page_id, references(:pages, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:sections, [:page_id])
  end
end
