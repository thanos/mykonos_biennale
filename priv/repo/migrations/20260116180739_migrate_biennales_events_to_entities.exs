defmodule MykonosBiennale.Repo.Migrations.MigrateBiennalesEventsToEntities do
  use Ecto.Migration

  def up do
    # Migrate Biennales to Entities
    execute """
    INSERT INTO entities (identity, type, slug, visible, fields, inserted_at, updated_at)
    SELECT 
      CAST(year AS TEXT),
      'biennale',
      CAST(year AS TEXT),
      true,
      json_object(
        'year', year,
        'theme', theme,
        'statement', statement,
        'description', description,
        'start_date', start_date,
        'end_date', end_date
      ),
      inserted_at,
      updated_at
    FROM biennales
    """

    # Migrate Events to Entities
    execute """
    INSERT INTO entities (identity, type, slug, visible, fields, inserted_at, updated_at)
    SELECT 
      title,
      'event',
      title || '-' || id,
      true,
      json_object(
        'title', title,
        'description', description,
        'type', type,
        'date', date,
        'location', location,
        'old_event_id', id,
        'old_biennale_id', biennale_id
      ),
      inserted_at,
      updated_at
    FROM events
    """

    # Create Relationships linking Events to Biennales
    execute """
    INSERT INTO relationships (name, slug, fields, subject_id, object_id, inserted_at, updated_at)
    SELECT 
      'belongs_to_biennale',
      'biennale_event',
      json_object(),
      event_entity.id,
      biennale_entity.id,
      event_entity.inserted_at,
      event_entity.updated_at
    FROM entities event_entity
    INNER JOIN entities biennale_entity 
      ON biennale_entity.type = 'biennale' 
      AND CAST(biennale_entity.fields->>'year' AS INTEGER) = CAST(event_entity.fields->>'old_biennale_id' AS INTEGER)
    WHERE event_entity.type = 'event'
      AND event_entity.fields->>'old_biennale_id' IS NOT NULL
    """
  end

  def down do
    # Remove relationships created for events
    execute """
    DELETE FROM relationships 
    WHERE slug = 'biennale_event'
    """

    # Remove migrated entities
    execute """
    DELETE FROM entities 
    WHERE type IN ('biennale', 'event')
    """
  end
end
