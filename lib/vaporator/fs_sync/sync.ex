defmodule Vaporator.Sync do
  @moduledoc """
  Evaluates Vaporator.Cache for file differences and
  pushes them to CloudFs.
  """

  require Logger

  alias Vaporator.CloudFs
  alias Vaporator.ClientFs
  alias Vaporator.Cache

  @cloudfs %Vaporator.Dropbox{
    access_token: Application.get_env(:vaporator, :dbx_token)
  }
  @cloudfs_root Application.get_env(:vaporator, :cloudfs_root)

  def sync_files do

    match_spec = [
      {{:"$1", %{clientfs: :"$2", cloudfs: :"$3"}},
      [{:"/=", :"$2", :"$3"}],
      [:"$1"]}
    ]

    {:ok, records} = Cache.select(match_spec)

    records
    |> Enum.map(
          fn path ->
            {:created, {ClientFs.which_sync_dir!(path), path}}
          end
        )
    |> Enum.map(&ClientFs.EventProducer.enqueue/1)
  end

  def cache_clientfs(path) do
    local_root = Path.absname(path)

    Logger.info("#{__MODULE__} STARTED cache of '#{local_root}'")

    case File.stat(local_root) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        DirWalker.stream(local_root)
        |> Enum.map(fn path ->
              {path, %{clientfs: CloudFs.get_hash!(@cloudfs, path)}}
           end)
        |> Enum.map(&Cache.update/1)

        Logger.info("#{__MODULE__} COMPLETED cache of '#{path}'")
        {:ok, local_root}

      {:error, :enoent} ->
        Logger.error("#{__MODULE__} bad local path in initial cache: '#{path}'")
        {:error, :bad_local_path}
    end
  end

  def cache_cloudfs(path) do

    Logger.info("#{__MODULE__} STARTED cache of '#{@cloudfs_root}'")

    {:ok, %{results: meta}} = CloudFs.list_folder(
                                @cloudfs,
                                Path.join(
                                  @cloudfs_root,
                                  Path.basename(path)
                                ),
                                %{recursive: true}
                              )

    meta
    |> Enum.filter(fn %{type: t} -> t == :file end)
    |> Enum.map(fn %{path: p, meta: m} ->
        {
          ClientFs.get_local_path!(@cloudfs_root, p),
          %{cloudfs: m["content_hash"]}
        }
      end)
    |> Enum.map(&Cache.update/1)

    Logger.info("#{__MODULE__} STARTED cache of '#{@cloudfs_root}'")
  end

end