defmodule MykonosBiennale.Content do
  @moduledoc """
  The Content context handles all Biennale and Event operations.
  """

  import Ecto.Query, warn: false
  alias MykonosBiennale.Repo
  alias MykonosBiennale.Content.{Biennale, Event}

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
  Returns an `%Ecto.Changeset{