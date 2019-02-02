defmodule Vaporator.ClientFs.Supervisor do
  use Supervisor

  @watch_dirs Application.get_env(:vaporator, :watch_dirs)

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    generate_children() |> Supervisor.init(strategy: :one_for_one)
  end

  @doc """
  Generates ClientFs children for configured watch directories.
  
  Returns:
    children (list): List of Vaporator.ClientFs child_specs
                    i.e. [
                      %{id: clientfs_dropbox, start: ...},
                      %{id: clientfs_onedrive, start: ...}
                    ]
  """
  def generate_children do
    @watch_dirs
    |> Enum.map(fn x -> [x] end) # path needs to be a list for start_link
    |> Enum.map(&child_spec/1)
  end

  @doc """
  Creates a map for a ClientFs process spec

  Args:
    path (binary): absolute filepath on ClientFs
  
  Returns:
    child_spec (map)
  """
  def child_spec(path) do
    %{
      id: generate_name(path),
      start: {
        Vaporator.ClientFs,
        :start_link,
        [path]
      }
    }
  end

  @doc """
  Generates a name from the provided path basename

  Args:
    path (binary): absolute filepath on ClientFs
  
  Returns:
    name (atom): generated name (i.e. :clientfs_dropbox)
  """
  def generate_name(path) do
    path
    |> Path.basename
    |> String.downcase
    |> String.replace(" ", "")
    |> fn x -> "clientfs_#{x}" end.()
    |> String.to_atom
  end
end
