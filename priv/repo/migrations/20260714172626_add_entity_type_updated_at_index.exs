defmodule MykonosBiennale.Repo.Migrations.AddEntityTypeUpdatedAtIndex do
  use Ecto.Migration

  def up do
    create index("entities", [:type, :visible, :updated_at],
             name: "idx_entities_type_visible_updated_at"
           )
  end

  def down do
    drop index("entities", [:type, :visible, :updated_at],
             name: "idx_entities_type_visible_updated_at"
           )
  end
end
