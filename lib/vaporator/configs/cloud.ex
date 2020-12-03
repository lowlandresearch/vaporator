defmodule Vaporator.Config.Cloud do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clouds" do
    field(:name, :string)
    field(:access_token, :string)
    field(:enabled, :boolean, default: false)

    timestamps()
  end

  def changeset(cloud, attrs \\ %{}) do
    cloud
    |> cast(attrs, [:name, :access_token, :enabled])
    |> validate_required([:name, :access_token])
    |> unique_constraint(:name)
  end

  def new do
    %__MODULE__{}
  end
end
