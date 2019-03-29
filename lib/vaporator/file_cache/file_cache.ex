defmodule Vaporator.FileCache do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    {:ok, state}
  end

  # Client

  def lookup(filepath) do
    GenServer.call(__MODULE__, {:lookup, filepath})
  end

  def insert(filepath) do
    GenServer.call(__MODULE__, {:insert, filepath})
  end

  def delete(filepath) do
    GenServer.call(__MODULE__, {:delete, filepath})
  end

  # Server

  def handle_call({:lookup, filepath}, _, cache) do
    case Map.fetch(cache, filepath) do
      {:ok, content} ->
        {:reply, content, cache}
      :error ->
        {:reply, :error, cache}
    end
  end

  def handle_call({:insert, filepath}, _, cache) do
    cache = Map.put_new(
        cache,
        filepath,
        %{
          clientfs_hash: Vaporator.Dropbox.dbx_hash!(filepath),
          cloudfs_hash: ""
        }
      )
    {:reply, filepath, cache}
  end

  def handle_call({:delete, filepath}, _, cache) do
    cache = Map.drop(cache, filepath)
    {:reply, :ok, cache}
  end

end