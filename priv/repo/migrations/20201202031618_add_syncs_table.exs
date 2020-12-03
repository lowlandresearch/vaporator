defmodule Vaporator.Repo.Migrations.AddSyncsTable do
  use Ecto.Migration

  def change do
    create table("syncs") do
      add :client_id, references("clients")
      add :client_base_path, :string

      add :cloud_id, references("clouds")
      add :cloud_base_path, :string

      add :enabled, :boolean, default: true

      timestamps()
    end

    create unique_index("syncs", [:client_id, :client_base_path, :cloud_id, :cloud_base_path], name: :syncs_unique_index)
  end
end
