defmodule Filesync.Client.FileSystem do
  @moduledoc """
  Handles interactions for mounting and unmounting filesystems.
  """

  require Logger

  def parse_options(opts) do
    parse_options(opts, [])
  end
  defp parse_options([], result), do: {:ok, ["-o" | result]}
  defp parse_options([{:filesystem_type, :cifs} | t], result) do
    parse_options(t, ["-t", "cifs" | result])
  end
  defp parse_options([{:filesystem_type, value} | _t], _result) do
    Logger.error("unknown value `#{inspect(value)}` for filesystem_type")
    {:error, :unknown_filesystem_type}
  end
  defp parse_options([{key, value} | t], result) do
    option_pair = "#{Atom.to_string(key)}=#{value}"
    parse_options(t, [option_pair | result])
  end

  @doc """
  Mounts a filesystem.

  Returns `{:ok, stdio}`

  ## Examples

    iex> Filesync.Client.FileSystem.mount([os_type: :win_xp, mount_point: "/path/dir"])
    {:ok, stdio}
  """
  def mount(mount_point, opts) do
    {:ok, opts} = parse_options(opts, [])
    udisksctl(["mount", "-p", mount_point | opts])
  end
  @doc """
  Unmounts a mounted filesystem.

  Returns `{:ok, stdio}`

  ## Examples

    iex> Filesync.Client.FileSystem.unmount("/path/dir")
    {:ok, stdio}
  """
  def unmount(mount_point) do
    udisksctl(["unmount", "-p" | mount_point])
  end

  def udisksctl(opts) do
    case System.cmd("udisksctl", opts, stderr_to_stdout: true) do
      {response, 0} -> {:ok, response}
      {response, _} -> {:error, response}
    end
  end

end