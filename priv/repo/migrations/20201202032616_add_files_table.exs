defmodule Vaporator.Repo.Migrations.AddFileTable do
  use Ecto.Migration

  def change do
    create table("files") do
      add :sync_id, references("syncs")
      add :client_path, :string
      add :client_hash, :string
      add :cloud_path, :string
      add :cloud_hash, :string

      timestamps()
    end

    create unique_index("files", [:client_path, :sync_id])
  end


end
