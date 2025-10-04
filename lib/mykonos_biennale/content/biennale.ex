defmodule MykonosBiennale.Content.Biennale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "biennales" do
    field :year, :integer
    field :theme, :string
    field :statement, :string
    field :description, :string
    field :start_date, :date
    field :end_date, :date

    has_many :events, MykonosBiennale.Content.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(biennale, attrs) do
    biennale
    |> cast(attrs, [:year, :theme, :statement, :description, :start_date, :end_date])
    |> validate_required([:year, :theme])
    |> validate_number(:year, greater_than: 2000, less_than: 2100)
    |> unique_constraint(:year)
  end
end
