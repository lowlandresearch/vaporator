defmodule Vaporator.Config.Sync do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vaporator.Config.{Client, Cloud}
  alias Vaporator.FileSystems.File

  schema "syncs" do
    belongs_to(:client, Client)
    field(:client_base_path, :string)

    belongs_to(:cloud, Cloud)
    field(:cloud_base_path, :string)

    field(:enabled, :boolean, default: true)

    has_many(:files, File)

    timestamps()
  end

  def changeset(file, attrs \\ %{}) do
    file
    |> cast(attrs, [:client_id, :client_base_path, :cloud_id, :cloud_base_path])
    |> validate_required([:client_id, :client_base_path, :cloud_id, :cloud_base_path])
    |> assoc_constraint(:cloud)
    |> assoc_constraint(:client)
    |> unique_constraint(:client_path, name: :syncs_unique_index)
  end

  def new do
    %__MODULE__{}
  end
end
