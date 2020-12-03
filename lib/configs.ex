defmodule Vaporator.Configs do
  import Ecto.Query

  alias Vaporator.Repo

  alias Vaporator.Configs.{Client, Cloud, Sync}

  def list_clients do
    Repo.all(Client)
  end

  def get_client!(id), do: Repo.get!(Client, id)

  def create_client(attrs \\ %{}) do
    Client.new()
    |> Client.changeset(attrs)
    |> Repo.insert()
  end

  def update_client(%Client{} = client, attrs \\ %{}) do
    client
    |> Client.changeset(attrs)
    |> Repo.update()
  end

  def delete_client(%Client{} = client) do
    Repo.delete(client)
  end

  def change_client(%Client{} = client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  def list_clouds do
    Repo.all(Cloud)
  end

  def get_cloud!(id), do: Repo.get!(Cloud, id)

  def create_cloud(attrs \\ %{}) do
    Cloud.new()
    |> Cloud.changeset(attrs)
    |> Repo.insert()
  end

  def update_cloud(%Cloud{} = cloud, attrs \\ %{}) do
    cloud
    |> Cloud.changeset(attrs)
    |> Repo.update()
  end

  def delete_cloud(%Cloud{} = cloud) do
    Repo.delete(cloud)
  end

  def change_cloud(%Cloud{} = cloud, attrs \\ %{}) do
    Cloud.changeset(cloud, attrs)
  end

  def list_syncs do
    Repo.all(Sync)
  end

  def get_sync!(id), do: Repo.get!(Sync, id)

  def create_sync(attrs \\ %{}) do
    Sync.new()
    |> Sync.changeset(attrs)
    |> Repo.insert()
  end

  def update_sync(%Sync{} = sync, attrs \\ %{}) do
    sync
    |> Sync.changeset(attrs)
    |> Repo.update()
  end

  def delete_sync(%Sync{} = sync) do
    Repo.delete(sync)
  end

  def change_sync(%Sync{} = sync, attrs \\ %{}) do
    Sync.changeset(sync, attrs)
  end
end
