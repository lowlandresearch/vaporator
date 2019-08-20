defmodule Vaporator.Client do
  @moduledoc """
  Provides a single interface for:
    - Receiving events streamed from Client and queues them into
      EventQueue
    - Processing events in EventQueue to determine necessary Cloud
      sync action
  """

  alias Vaporator.Settings

  require Logger

  @doc """
  Sets the poll interval, in milliseconds, for how often the host sync directories are synced.

  Returns `tuple`

  Examples
    ```elixir
    iex> Vaporator.Client.set_poll_interval(150000)
    {:ok, 5000}

    iex> Vaporator.Client.set_poll_interval(5000)
    {:error, "interval must be >= 10 seconds"}

    iex> Vaporator.Client.set_poll_interval("10000")
    {:error, "interval must be an integer"}
    ```
  """
  def set_poll_interval(interval) when is_integer(interval) do
    if interval < 10000 do
      {:error, "interval must be >= 10 seconds"}
    else
      Settings.put(:poll_interval, interval)
    end
  end

  def set_poll_interval(_) do
    {:error, "interval must be an integer"}
  end

  @doc """
  Adds a directory to the list of directories that will be synced.

  Returns `:ok`

  Examples
    ```elixir
    iex> Vaporator.Client.add_sync_dir("/path/to/a/dir")
    :ok
    ```
  """
  def add_sync_dir(path) do
    setting = Settings.get(:sync_dirs)
    Settings.put(:sync_dirs, [path | setting])
  end

  @doc """
  Removes a directory to the list of directories that will be synced.

  Returns `:ok`

  Examples
    ```elixir
    iex> Vaporator.Client.remove_sync_dir("/path/to/a/dir")
    :ok
    ```
  """
  def remove_sync_dir(path) do
    setting = Settings
    new_setting = List.delete(setting, path)
    Settings.put(:sync_dirs, new_setting)
  end

  @doc """
  Creates a file in Cloud filesystem.

  Returns `tuple`

  Examples
    ```elixir
    iex> Vaporator.Client.process_event(:created, {"/mnt/windows", "foo/bar.txt"})
    {:ok, %Vaporator.Cloud.Meta{...}}

    iex> Vaporator.Client.process_event(:created, {"/mnt/windows", "foo/nofile.txt"})
    {:error, ...}
    ```
  """
  def process_event({:created, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloud = Settings.get(:cloud)

      cloud_path =
        Vaporator.Cloud.get_path(
          cloud.provider,
          root,
          path,
          cloud.provider.root_path
        )

      Logger.info(
        "#{__MODULE__} CREATED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloud_path}"
      )

      case Vaporator.Cloud.file_upload(
             cloud.provider,
             path,
             cloud_path
           ) do
        {:ok, meta} ->
          Logger.info("#{__MODULE__} upload SUCCESS.")
          {:ok, meta}

        {:error, reason} ->
          Logger.error("#{__MODULE__} upload FAILURE: #{reason}")
          {:error, reason}
      end
    end
  end

  @doc """
  Updates a file in Cloud filesystem.

  Returns `tuple`

  Examples
    ```elixir
    iex> Vaporator.Client.process_event(:updated, {"/mnt/windows", "foo/bar.txt"})
    {:ok, %Vaporator.Cloud.Meta{...}}

    iex> Vaporator.Client.process_event(:updated, {"/mnt/windows", "foo/nofile.txt"})
    {:error, ...}
    ```
  """
  def process_event({:updated, {root, path}}) do
    if not File.dir?(path) and File.exists?(path) do
      cloud = Settings.get(:cloud)

      cloud_path =
        Vaporator.Cloud.get_path(
          cloud.provider,
          root,
          path,
          cloud.provider.root_path
        )

      Logger.info(
        "#{__MODULE__} MODIFIED event:\n" <>
          "  local path: #{path}\n" <>
          "  cloud path: #{cloud_path}"
      )

      case Vaporator.Cloud.file_update(
             cloud.provider,
             path,
             cloud_path
           ) do
        {:ok, meta} ->
          Logger.info("#{__MODULE__} update SUCCESS.")
          {:ok, meta}

        {:error, reason} ->
          Logger.error("#{__MODULE__} update FAILURE: #{reason}")
          {:error, reason}
      end
    end
  end

  @doc """
  Removes a file from Cloud filesystem.

  Returns `tuple`

  Examples
    ```elixir
    iex> Vaporator.Client.process_event(:removed, {"/mnt/windows", "foo/bar.txt"})
    {:ok, %Vaporator.Cloud.Meta{...}}

    iex> Vaporator.Client.process_event(:removed, {"/mnt/windows", "foo/nofile.txt"})
    {:error, ...}
    ```
  """
  def process_event({:removed, {root, path}}) do
    cloud = Settings.get(:cloud)

    cloud_path =
      Vaporator.Cloud.get_path(
        cloud.provider,
        root,
        path,
        cloud.provider.root_path
      )

    Logger.info(
      "#{__MODULE__} DELETED event:\n" <>
        "  local path: #{path}\n" <>
        "  cloud path: #{cloud_path}"
    )

    if File.dir?(path) do
      Vaporator.Cloud.folder_remove(
        cloud.provider,
        cloud_path
      )
    else
      Vaporator.Cloud.file_remove(
        cloud.provider,
        cloud_path
      )
    end
  end

  def process_event({event, _}) do
    Logger.error("#{__MODULE__} unhandled event -> #{event}")
  end

  @doc """
  Determines to which sync directory does a given path belong.

  Returns `binary`

  Examples
    ```elixir
    iex> Vaporator.Client.which_sync_dir!("/vaporator/foo/bar.txt")
    "/mnt/windows"
    ```
  """
  def which_sync_dir!(path) do
    sync_dirs = Settings.get!(:client, :sync_dirs)

    sync_dirs
    |> Enum.filter(fn root -> String.starts_with?(path, root) end)
    |> Enum.fetch!(0)
  end

  @doc """
  Given a cloud_root, the cloud_path within it, and a local_root, what
  is the local_path?

  Returns `binary`

  Examples
    ```elixir
    iex> Vaporator.Client.get_local_path!("/vaporator/foo", /vaporator/foo/bar.txt")
    "/mnt/windows/foo/bar.txt"
    ```
  """
  def get_local_path!(cloud_root, cloud_path) do
    path =
      Path.relative_to(
        cloud_path |> Path.absname(),
        cloud_root |> Path.absname()
      )

    path_root =
      path
      |> Path.split()
      |> List.first()

    sync_dirs = Settings.get!(:client, :sync_dirs)

    sync_dirs
    |> Enum.filter(fn x ->
      String.ends_with?(x, path_root)
    end)
    |> Path.dirname()
    |> Path.join(path)
  end
end
