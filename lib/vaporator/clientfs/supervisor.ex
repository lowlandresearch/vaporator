defmodule Vaporator.ClientFs.Supervisor do
  use Supervisor

  @watch_dirs Application.get_env(:vaporator, :watch_dirs)

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    @watch_dirs
    |> Enum.map(fn x -> [x] end) # path needs to be a list for start_link
    |> Enum.map(&child_spec/1)
    |> Supervisor.init(strategy: :one_for_one)
  end

  def generate_name(path) do
    path
    |> Path.basename
    |> String.downcase
    |> String.replace(" ", "")
    |> fn x -> "clientfs_#{x}" end.()
    |> String.to_atom
  end

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
end
