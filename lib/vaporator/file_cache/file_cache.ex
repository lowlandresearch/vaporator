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
    files = :ets.new(table, [:protected])
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
    GenServer.call(__MODULE__, {:lookup, filepath})
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
    GenServer.cast(__MODULE__, {:update, filepath, hashes})
  end

  @doc """
  Deletes filepath record from cache asynchronously

  Args:
    filepath (binary): used as key in cache

  Returns:
    :ok (Atom)
  """
  def delete(filepath) do
    GenServer.cast(__MODULE__, {:delete, filepath})
  end

  # Server

  def handle_call({:lookup, filepath}, _, cache) do
    case :ets.lookup(cache, filepath) do
      [{^filepath, hashes}] ->
        {:reply, hashes, cache}

      [] ->
        {:reply, :error, cache}
    end
  end

  def handle_cast({:update, filepath, hashes}, cache) do
    :ets.insert(cache, {filepath, hashes})
    {:noreply, cache}
  end

  def handle_cast({:delete, filepath}, cache) do
    :ets.delete(cache, filepath)
    {:noreply, cache}
  end

  def handle_cast({:insert, filepath}, cache) do
    record = {
      filepath,
      %{
        clientfs: Vaporator.Dropbox.dbx_hash!(filepath),
        cloudfs: ""
      }
    }

    :ets.insert_new(cache, record)
    {:noreply, cache}
  end

end