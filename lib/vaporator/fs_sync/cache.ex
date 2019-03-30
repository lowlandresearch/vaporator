defmodule Vaporator.Cache do
  @moduledoc """
  Cache for storing ClientFs and CloudFs file hashes that will be
  used to determine what should be synced to CloudFs.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    table = :ets.new(:cache, [:named_table, :protected])
    {:ok, table}
  end

  # Client

  @doc """
  Looks up the hashes for a local_path

  Args:
    local_path (binary): used as key in cache

  Returns:
    hashes (Map)
  """
  def lookup(local_path) do
    GenServer.call(__MODULE__, {:lookup, local_path})
  end

  @doc """
  Inserts new local_path record into cache asynchronously

  Args:
    local_path (binary): used as key in cache

  Returns:
    :ok (Atom)
  """
  def insert(cloudfs, local_path) do
    GenServer.cast(__MODULE__, {:insert, cloudfs, local_path})
  end

  @doc """
  Updates local_path record in cache asynchronously

  Args:
    local_path (binary): used as key in cache
    hashes (Map): new hashes to overwrite old hashes

  Returns:
    :ok (Atom)
  """
  def update(local_path, hashes) do
    GenServer.cast(__MODULE__, {:update, local_path, hashes})
  end

  @doc """
  Deletes local_path record from cache asynchronously

  Args:
    local_path (binary): used as key in cache

  Returns:
    :ok (Atom)
  """
  def delete(local_path) do
    GenServer.cast(__MODULE__, {:delete, local_path})
  end

  # Server

  def handle_call({:lookup, local_path}, _, cache) do
    case :ets.lookup(cache, local_path) do
      [{^local_path, hashes}] ->
        {:reply, hashes, cache}

      [] ->
        {:reply, :error, cache}
    end
  end

  def handle_cast({:update, local_path, hashes}, cache) do
    :ets.insert(cache, {local_path, hashes})
    {:noreply, cache}
  end

  def handle_cast({:delete, local_path}, cache) do
    :ets.delete(cache, local_path)
    {:noreply, cache}
  end

  def handle_cast({:insert, cloudfs, local_path}, cache) do
    record = {
      local_path,
      %{
        clientfs: Vaporator.CloudFs.get_hash!(cloudfs, local_path),
        cloudfs: ""
      }
    }

    :ets.insert_new(cache, record)
    {:noreply, cache}
  end

end