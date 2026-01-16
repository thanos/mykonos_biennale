defmodule MykonosBiennale.Content.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entities" do
    field :identity, :string
    field :type, :string
    field :slug, :string
    field :visible, :boolean, default: false
    field :fields, :map

    has_many(:as_subject, MykonosBiennale.Content.Relationship, foreign_key: :subject_id)
    has_many(:as_object, MykonosBiennale.Content.Relationship, foreign_key: :object_id)
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entity, attrs, _meta \\ []) do
    entity
    |> cast(attrs, [:identity, :type, :slug, :visible, :fields])
    |> validate_required([:identity, :type, :slug, :visible])
  end
end
