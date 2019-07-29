defmodule Filesync.Client.FileSystem do
  @moduledoc """
  Handles interactions for mounting and unmounting filesystems.
  """

  require Logger

  @required_arguments [:filesystem_type]
  @supported_filesystem_types [:cifs]

  defp supported_filesystem_type?(filesystem_type) do
    Enum.member?(@supported_filesystem_types, filesystem_type)
  end

  defp required_argument?(arg) do
    Enum.member?(@required_arguments, arg)
  end

  defp contains_required_arguments?(opts) do
    opts
    |> Keyword.keys()
    |> Enum.filter(&required_argument?/1)
    |> Enum.sort()
    |> fn x -> x == Enum.sort(@required_arguments) end.()
  end

  def parse_options(opts) do 
    if contains_required_arguments?(opts) do
      parse_options(opts, [])
    else
      {:error, :missing_required_arguments}
    end
  end

  defp parse_options([], result), do: {:ok, result}

  defp parse_options([{:filesystem_type, type} | t], result) do
    if supported_filesystem_type?(type) do
      parse_options(t, ["-t", Atom.to_string(type) | result])
    else
      {:error, :unknown_filesystem_type}
    end
  end

  defp parse_options([{key, value} | t], result) do
    option_pair = "#{Atom.to_string(key)}=#{value}"

    if t == [] do
      parse_options(t, ["-o", option_pair | result])
    else
      parse_options(t, [option_pair | result])
    end
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