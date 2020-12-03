defmodule Vaporator.Repo.Migrations.AddClientCloudTables do
  use Ecto.Migration

  def change do
    create table("clients") do
      add :name, :string
      add :ip_address, :string
      add :os_type, :string
      add :available, :boolean, default: true

      timestamps()
    end

    create unique_index("clients", [:ip_address])

    create table("clouds") do
      add :name, :string
      add :access_token, :string
      add :enabled, :boolean, default: false

      timestamps()
    end

    create unique_index("clouds", [:name])
  end
end
