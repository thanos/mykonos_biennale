defmodule MykonosBiennale.Repo.Migrations.DropOldBiennalesAndEventsTables do
  use Ecto.Migration

  def change do
    drop table(:events)
    drop table(:biennales)
  end
end
