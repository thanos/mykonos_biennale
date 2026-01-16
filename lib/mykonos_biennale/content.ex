defmodule MykonosBiennale.Content do
  @moduledoc """
  The Content context handles all Biennale and Event operations.
  """

  import Ecto.Query, warn: false
  alias MykonosBiennale.Repo
  alias MykonosBiennale.Content.{Entity, Relationship, Media}

  ## Backward-compatible helper functions for Biennales/Events

  @doc """
  Returns the list of biennales (entities with type "biennale") ordered by year descending.
  """
  def list_biennales do
    Repo.all(
      from e in Entity,
        where: e.type == "biennale",
        order_by: [desc: fragment("CAST(? ->> ? AS INTEGER)", e.fields, "year")]
    )
  end

  @doc """
  Gets a single biennale entity by ID.

  Raises `Ecto.NoResultsError` if the Entity does not exist.
  """
  def get_biennale!(id), do: Repo.get!(Entity, id)

  @doc """
  Gets a biennale entity by year.
  Returns `nil` if not found.
  """
  def get_biennale_by_year(year) do
    Repo.one(
      from e in Entity,
        where:
          e.type == "biennale" and fragment("CAST(? ->> ? AS INTEGER)", e.fields, "year") == ^year
    )
  end

  @doc """
  Creates a biennale entity.
  """
  def create_biennale(attrs \\ %{}) do
    fields = %{
      "year" => Map.get(attrs, :year) || Map.get(attrs, "year"),
      "theme" => Map.get(attrs, :theme) || Map.get(attrs, "theme"),
      "statement" => Map.get(attrs, :statement) || Map.get(attrs, "statement"),
      "description" => Map.get(attrs, :description) || Map.get(attrs, "description"),
      "start_date" => Map.get(attrs, :start_date) || Map.get(attrs, "start_date"),
      "end_date" => Map.get(attrs, :end_date) || Map.get(attrs, "end_date")
    }

    year = fields["year"]

    create_entity(%{
      identity: to_string(year),
      type: "biennale",
      slug: to_string(year),
      # Default to true, allow override
      visible: Map.get(attrs, :visible, true),
      fields: fields
    })
  end

  @doc """
  Updates a biennale entity.
  """
  def update_biennale(%Entity{} = biennale_entity, attrs) do
    current_fields = biennale_entity.fields

    new_fields =
      Enum.reduce(
        [:year, :theme, :statement, :description, :start_date, :end_date],
        current_fields,
        fn key, acc ->
          case Map.get(attrs, key) do
            nil -> acc
            value -> Map.put(acc, to_string(key), value)
          end
        end
      )

    update_entity(biennale_entity, %{
      identity: to_string(new_fields["year"]),
      slug: to_string(new_fields["year"]),
      visible: Map.get(attrs, :visible, biennale_entity.visible),
      fields: new_fields
    })
  end

  @doc """
  Deletes a biennale entity and its associated relationships.
  """
  def delete_biennale(%Entity{} = biennale_entity) do
    # Delete associated relationships first where this biennale is the object
    Repo.delete_all(from r in Relationship, where: r.object_id == ^biennale_entity.id)
    # Then delete the biennale entity
    delete_entity(biennale_entity)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking biennale entity changes.
  """
  def change_biennale(%Entity{} = biennale_entity, attrs \\ %{}) do
    # Map attrs to entity fields for the changeset
    entity_attrs = %{
      identity: Map.get(attrs, :year) && to_string(Map.get(attrs, :year)),
      slug: Map.get(attrs, :year) && to_string(Map.get(attrs, :year)),
      visible: Map.get(attrs, :visible),
      fields:
        Map.take(attrs, [:year, :theme, :statement, :description, :start_date, :end_date])
        |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
    }

    Entity.changeset(biennale_entity, entity_attrs)
  end

  @doc """
  Returns the list of events (entities with type "event") for a given biennale year.
  Uses relationships to find events linked to the biennale.
  """
  def list_events_for_biennale(biennale_year) do
    biennale_entity = get_biennale_by_year(biennale_year)

    if biennale_entity do
      Repo.all(
        from e in Entity,
          join: r in assoc(e, :as_subject),
          where:
            e.type == "event" and r.object_id == ^biennale_entity.id and
              r.slug == "biennale_event",
          order_by: [asc: fragment("? ->> ?", e.fields, "date")]
      )
    else
      []
    end
  end

  @doc """
  Returns the list of all events (entities with type "event").
  """
  def list_events do
    Repo.all(
      from e in Entity,
        where: e.type == "event",
        order_by: [asc: fragment("? ->> ?", e.fields, "date")]
    )
  end

  @doc """
  Gets a single event entity by ID.

  Raises `Ecto.NoResultsError` if the Entity does not exist.
  """
  def get_event!(id), do: Repo.get!(Entity, id)

  @doc """
  Creates an event entity and links it to a biennale via relationship.
  """
  def create_event(attrs \\ %{}) do
    title = Map.get(attrs, :title) || Map.get(attrs, "title")
    # This is the entity ID of the biennale
    biennale_entity_id = Map.get(attrs, :biennale_id) || Map.get(attrs, "biennale_id")

    fields = %{
      "title" => title,
      "description" => Map.get(attrs, :description) || Map.get(attrs, "description"),
      "type" => Map.get(attrs, :type) || Map.get(attrs, "type"),
      "date" => Map.get(attrs, :date) || Map.get(attrs, "date"),
      "time" => Map.get(attrs, :time) || Map.get(attrs, "time"),
      "location" => Map.get(attrs, :location) || Map.get(attrs, "location"),
      "tickets" => Map.get(attrs, :tickets) || Map.get(attrs, "tickets")
    }

    # Ensure slug is unique for events, can use UUID or title + current timestamp
    slug = "#{slugify(title || "event")}-#{System.monotonic_time()}"

    case create_entity(%{
           identity: title,
           type: "event",
           slug: slug,
           visible: Map.get(attrs, :visible, true),
           fields: fields
         }) do
      {:ok, event_entity} ->
        if biennale_entity_id do
          case get_entity!(biennale_entity_id) do
            %Entity{} = biennale_entity ->
              create_relationship(%{
                name: "belongs_to_biennale",
                slug: "biennale_event",
                fields: %{},
                subject_id: event_entity.id,
                object_id: biennale_entity.id
              })

              {:ok, event_entity}

            _ ->
              # If biennale entity not found, return event creation success
              {:ok, event_entity}
          end
        else
          {:ok, event_entity}
        end

      error ->
        error
    end
  end

  @doc """
  Updates an event entity and its relationship to a biennale.
  """
  def update_event(%Entity{} = event_entity, attrs) do
    current_fields = event_entity.fields

    new_fields =
      Enum.reduce(
        [:title, :description, :type, :date, :time, :location, :tickets],
        current_fields,
        fn key, acc ->
          case Map.get(attrs, key) do
            nil -> acc
            value -> Map.put(acc, to_string(key), value)
          end
        end
      )

    title = Map.get(attrs, :title) || new_fields["title"]
    biennale_entity_id = Map.get(attrs, :biennale_id) || Map.get(attrs, "biennale_id")

    updated_entity_changeset =
      update_entity(event_entity, %{
        identity: title,
        visible: Map.get(attrs, :visible, event_entity.visible),
        fields: new_fields
      })

    case updated_entity_changeset do
      {:ok, updated_event_entity} ->
        # Handle relationship update
        if biennale_entity_id do
          biennale_entity = get_entity!(biennale_entity_id)

          case Repo.get_by(Relationship,
                 subject_id: updated_event_entity.id,
                 slug: "biennale_event"
               ) do
            %Relationship{} = relationship ->
              # Update existing relationship if object_id is different
              if relationship.object_id != biennale_entity.id do
                update_relationship(relationship, %{object_id: biennale_entity.id})
              else
                {:ok, relationship}
              end

            _ ->
              # Create new relationship if none exists
              create_relationship(%{
                name: "belongs_to_biennale",
                slug: "biennale_event",
                fields: %{},
                subject_id: updated_event_entity.id,
                object_id: biennale_entity.id
              })
          end
        else
          # If biennale_id is explicitly nil, remove any existing relationship
          Repo.delete_all(
            from r in Relationship,
              where: r.subject_id == ^updated_event_entity.id and r.slug == "biennale_event"
          )
        end

        {:ok, updated_event_entity}

      error ->
        error
    end
  end

  @doc """
  Deletes an event entity and its associated relationships.
  """
  def delete_event(%Entity{} = event_entity) do
    # Delete associated relationships first
    Repo.delete_all(from r in Relationship, where: r.subject_id == ^event_entity.id)
    # Then delete the event entity
    delete_entity(event_entity)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event entity changes.
  """
  def change_event(%Entity{} = event_entity, attrs \\ %{}) do
    # Map attrs to entity fields for the changeset
    event_fields_to_map = [:title, :description, :type, :date, :time, :location, :tickets]

    fields_map =
      Map.take(attrs, event_fields_to_map)
      |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)

    entity_attrs = %{
      identity: Map.get(attrs, :title),
      visible: Map.get(attrs, :visible),
      fields: fields_map
    }

    Entity.changeset(event_entity, entity_attrs)
  end

  ## Entities

  @doc """
  Returns the list of entities.
  """
  def list_entities do
    Repo.all(from e in Entity, order_by: e.inserted_at)
  end

  @doc """
  Returns the list of visible entities.
  """
  def list_visible_entities do
    Repo.all(from e in Entity, where: e.visible == true, order_by: e.inserted_at)
  end

  @doc """
  Gets a single entity.
  """
  def get_entity!(id) do
    Repo.get!(Entity, id) |> Repo.preload([:as_subject, :as_object])
  end

  @doc """
  Gets an entity by slug.
  """
  def get_entity_by_slug(slug) do
    Repo.get_by(Entity, slug: slug) |> Repo.preload([:as_subject, :as_object])
  end

  @doc """
  Creates an entity.
  """
  def create_entity(attrs \\ %{}) do
    %Entity{}
    |> Entity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an entity.
  """
  def update_entity(%Entity{} = entity, attrs) do
    entity
    |> Entity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an entity.
  """
  def delete_entity(%Entity{} = entity) do
    Repo.delete(entity)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entity changes.
  """
  def change_entity(%Entity{} = entity, attrs \\ %{}) do
    Entity.changeset(entity, attrs)
  end

  ## Relationships

  @doc """
  Returns the list of relationships.
  """
  def list_relationships do
    Repo.all(from r in Relationship, preload: [:subject, :object])
  end

  @doc """
  Gets a single relationship.
  """
  def get_relationship!(id) do
    Repo.get!(Relationship, id) |> Repo.preload([:subject, :object])
  end

  @doc """
  Creates a relationship.
  """
  def create_relationship(attrs \\ %{}) do
    %Relationship{}
    |> Relationship.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a relationship.
  """
  def update_relationship(%Relationship{} = relationship, attrs) do
    relationship
    |> Relationship.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a relationship.
  """
  def delete_relationship(%Relationship{} = relationship) do
    Repo.delete(relationship)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking relationship changes.
  """
  def change_relationship(%Relationship{} = relationship, attrs \\ %{}) do
    Relationship.changeset(relationship, attrs)
  end

  ## Media

  @doc """
  Returns the list of media.
  """
  def list_media do
    Repo.all(from m in Media, order_by: [desc: m.inserted_at])
  end

  @doc """
  Gets a single media.
  """
  def get_media!(id), do: Repo.get!(Media, id)

  @doc """
  Creates a media.
  """
  def create_media(attrs \\ %{}) do
    %Media{}
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a media.
  """
  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a media.
  """
  def delete_media(%Media{} = media) do
    Repo.delete(media)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking media changes.
  """
  def change_media(%Media{} = media, attrs \\ %{}) do
    Media.changeset(media, attrs)
  end

  defp slugify(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim_leading("-")
    |> String.trim_trailing("-")
  end
end
