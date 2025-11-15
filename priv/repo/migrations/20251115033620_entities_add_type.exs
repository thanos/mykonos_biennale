defmodule MykonosBiennale.Repo.Migrations.EntitiesAddType do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add :type, :string
    end
  end
end
