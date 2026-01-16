defmodule MykonosBiennale.Content do
  @moduledoc """
  The Content context handles all Biennale and Event operations.
  """

  import Ecto.Query, warn: false
  alias MykonosBiennale.Repo
  alias MykonosBiennale.Content.{Biennale, Event, Entity, Relationship}

  @doc """
  Returns the list of biennales ordered by year descending.

  ## Examples

      iex> list_biennales()
      [%Biennale{}, ...]

  """
  def list_biennales do
    Repo.all(from b in Biennale, order_by: [desc: b.year])
  end

  @doc """
  Gets a single biennale.

  Raises `Ecto.NoResultsError` if the Biennale does not exist.

  ## Examples

      iex> get_biennale!(123)
      %Biennale{}

      iex> get_biennale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_biennale!(id), do: Repo.get!(Biennale, id)

  @doc """
  Gets a biennale by year.

  Returns `nil` if not found.

  ## Examples

      iex> get_biennale_by_year(2025)
      %Biennale{}

      iex> get_biennale_by_year(1999)
      nil

  """
  def get_biennale_by_year(year) do
    Repo.get_by(Biennale, year: year)
  end

  @doc """
  Creates a biennale.

  ## Examples

      iex> create_biennale(%{field: value})
      {:ok, %Biennale{}}

      iex> create_biennale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_biennale(attrs \\ %{}) do
    %Biennale{}
    |> Biennale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a biennale.

  ## Examples

      iex> update_biennale(biennale, %{field: new_value})
      {:ok, %Biennale{}}

      iex> update_biennale(biennale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_biennale(%Biennale{} = biennale, attrs) do
    biennale
    |> Biennale.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a biennale.

  ## Examples

      iex> delete_biennale(biennale)
      {:ok, %Biennale{}}

      iex> delete_biennale(biennale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_biennale(%Biennale{} = biennale) do
    Repo.delete(biennale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking biennale changes.

  ## Examples

      iex> change_biennale(biennale)
      %Ecto.Changeset{data: %Biennale{}}

  """
  def change_biennale(%Biennale{} = biennale, attrs \\ %{}) do
    Biennale.changeset(biennale, attrs)
  end

  @doc """
  Returns the list of events for a given biennale.

  ## Examples

      iex> list_events_for_biennale(biennale_id)
      [%Event{}, ...]

  """
  def list_events_for_biennale(biennale_id) do
    Repo.all(from e in Event, where: e.biennale_id == ^biennale_id, order_by: [asc: e.date])
  end

  @doc """
  Returns the list of all events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    Repo.all(from e in Event, order_by: [asc: e.date])
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates an event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
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
end
