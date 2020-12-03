defmodule Vaporator.FileSystems.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vaporator.Config.Sync

  schema "files" do
    belongs_to(:sync, Sync)
    field(:client_path, :string)
    field(:client_hash, :string)
    field(:cloud_path, :string)
    field(:cloud_hash, :string)

    timestamps()
  end

  def changeset(file, attrs \\ %{}) do
    file
    |> cast(attrs, [:client_path, :client_hash, :cloud_path, :cloud_hash, :sync_id])
    |> validate_required([:client_path, :client_hash, :cloud_path, :sync_id])
    |> assoc_constraint(:sync)
    |> unique_constraint(:client_path, name: :files_client_path_sync_id_index)
  end

  def new do
    %__MODULE__{}
  end
end
