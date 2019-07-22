defmodule FileHashes do
  @moduledoc """
  Struct for file hashes
  """
  defstruct [:clientfs, :cloudfs]
end

defmodule Filesync.Cache do
  @moduledoc """
  Cache for storing ClientFs and CloudFs file hashes that will be
  used to determine what should be synced to CloudFs.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, table} = Ets.Set.new()
    {:ok, table}
  end

  # Client

  @doc """
  Select query for cache ets table

  Args:
    match_spec (:erlang match_spec)
      http://erlang.org/doc/man/ets.html#type-match_spec

  Returns:
    result (tuple): {:ok, records :: List}
  """
  def select(match_spec) do
    GenServer.call(__MODULE__, {:select, match_spec})
  end

  @doc """
  Updates local_path hashes with a new value.

  If local_path exists in cache, the %FileHashes are updated.
  If local_path doesn't exist in cache, a new record is inserted.
  Args:
    update (tuple): {local_path, Map}
                    Ex: {"/watch/test.txt", %{cloudfs: "1234"}}

  Returns:
    result (tuple): {:ok, local_path} when update success
  """
  def update({_local_path, %{}}=record) do
    GenServer.call(__MODULE__, {:update, record})
  end

  # Server

  def handle_call({:select, match_spec}, _, cache) do
    {:reply, Ets.Set.select(cache, match_spec), cache}
  end

  def handle_call({:update, {local_path, hash}}, _, cache) do
    case Ets.Set.get(cache, local_path) do
      {:ok, {^local_path, hashes}} ->
        record = {local_path, Map.merge(hashes, hash)}
        Ets.Set.put(cache, record)
        {:reply, {:ok, local_path}, cache}

      _ ->
        record = {local_path, Map.merge(%FileHashes{}, hash)}
        Ets.Set.put(cache, record)
        {:reply, {:ok, local_path}, cache}
    end
  end

end