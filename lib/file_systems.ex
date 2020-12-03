defmodule Vaporator.FileSystems do
  import Ecto.Query

  alias Vaporator.Repo

  alias Vaporator.FileSystems.File

  def list_files do
    Repo.all(File)
  end

  def get_file!(id), do: Repo.get!(File, id)

  def create_file(attrs \\ %{}) do
    File.new()
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  def update_file(%File{} = file, attrs \\ %{}) do
    file
    |> File.changeset(attrs)
    |> Repo.update()
  end

  def delete_file(%File{} = file) do
    Repo.delete(file)
  end

  def change_file(%File{} = file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end
end
