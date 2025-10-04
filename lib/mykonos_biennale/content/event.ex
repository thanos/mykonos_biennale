defmodule MykonosBiennale.Content.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @event_types [
    "exhibition",
    "performance",
    "video_graffiti",
    "dramatic_nights",
    "short_films",
    "workshop"
  ]

  schema "events" do
    field :title, :string
    field :type, :string
    field :date, :date
    field :location, :string
    field :description, :string

    belongs_to :biennale, MykonosBiennale.Content.Biennale

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :type, :date, :location, :description, :biennale_id])
    |> validate_required([:title, :type, :biennale_id])
    |> validate_inclusion(:type, @event_types)
    |> foreign_key_constraint(:biennale_id)
  end

  def event_types, do: @event_types
end
