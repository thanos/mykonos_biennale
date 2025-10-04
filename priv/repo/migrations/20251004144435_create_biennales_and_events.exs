defmodule MykonosBiennale.Repo.Migrations.CreateBiennalesAndEvents do
  use Ecto.Migration

  def change do
    create table(:biennales) do
      add :year, :integer, null: false
      add :theme, :string, null: false
      add :statement, :text
      add :description, :text
      add :start_date, :date
      add :end_date, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:biennales, [:year])

    create table(:events) do
      add :title, :string, null: false
      add :type, :string, null: false
      add :date, :date
      add :location, :string
      add :description, :text
      add :biennale_id, references(:biennales, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:biennale_id])
    create index(:events, [:type])
    create index(:events, [:date])
  end
end
