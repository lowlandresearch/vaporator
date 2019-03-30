defmodule Vaporator.FileCache do
  @moduledoc """
  Cache for storing ClientFs and CloudFs file hashes that will be
  used to determine what should be synced to CloudFs.
  """
  use GenServer

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table, opts)
  end

  def init(table) do
    files = :ets.new(table, [:named_table, :protected])
    {:ok, files}
  end

  # Client

  @doc """
  Looks up the hashes for a filepath

  Args:
    filepath (binary): used as key in cache

  Returns:
    hashes (Map)
  """
  def lookup(filepath) do
    file = string_hash(filepath)
    GenServer.call(__MODULE__, {:lookup, file})
  end

  @doc """
  Inserts new filepath record into cache asynchronously

  Args:
    filepath (binary): used as key in cache

  Returns:
    :ok (Atom)
  """
  def insert(filepath) do
    GenServer.cast(__MODULE__, {:insert, filepath})
  end

  @doc """
  Updates filepath record in cache asynchronously

  Args:
    filepath (binary): used as key in cache
    hashes (Map): new hashes to overwrite old hashes

  Returns:
    :ok (Atom)
  """
  def update(filepath, hashes) do
    file = string_hash(filepath)
    GenServer.cast(__MODULE__, {:update, file, hashes})
  end

  @doc """
  Deletes filepath record from cache asynchronously

  Args:
    filepath (binary): used as key in cache

  Returns:
    :ok (Atom)
  """
  def delete(filepath) do
    file = string_hash(filepath)
    GenServer.cast(__MODULE__, {:delete, file})
  end

  defp string_hash(s) do
    hash = :crypto.hash(:md5, s)

    hash
    |> Base.encode16()
    |> String.downcase()
  end

  # Server

  def handle_call({:lookup, file}, _, cache) do
    case :ets.lookup(cache, file) do
      [{^file, hashes}] ->
        {:reply, hashes, cache}

      [] ->
        {:reply, :error, cache}
    end
  end

  def handle_cast({:update, file, hashes}, cache) do
    :ets.insert(cache, {file, hashes})
    {:noreply, cache}
  end

  def handle_cast({:delete, file}, cache) do
    :ets.delete(cache, file)
    {:noreply, cache}
  end

  def handle_cast({:insert, filepath}, cache) do
    record = {
      string_hash(filepath),
      %{
        clientfs: Vaporator.Dropbox.dbx_hash!(filepath),
        cloudfs: ""
      }
    }

    :ets.insert_new(cache, record)
    {:noreply, cache}
  end

end