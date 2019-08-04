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
    |> (fn x -> x == Enum.sort(@required_arguments) end).()
  end

  @doc """
  Parses options and builds command for `udisksctl`

  Returns `{:ok, options}`

  ## Examples

    iex> Filesync.Client.FileSystem.parse_options([filesystem_type: :win_xp, username: "chaz"])
    {:ok, options}
  """
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

  def smbclient(server, share, opts) do
    case System.cmd("smclient", opts, stderr_to_stdout: true) do
      {response, 0} -> {:ok, response}
      {response, _} -> {:error, response}
    end
  end
end
