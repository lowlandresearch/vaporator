defprotocol Vaporator.CloudFs do
  @doc "Protocol for the most basic set of Cloud file-system operations"

  # Need to be able to get the contents of a folder. Should return
  # List of CloudFs.Meta
  def list_folder(fs, path)       # /2 for normal use
  def list_folder(fs, path, args) # /3 for optional args

  # Need to be able to get the metadata of an inode at a particular
  # path. Should return CloudFs.Meta
  def get_metadata(fs, path)       # /2 for normal use
  def get_metadata(fs, path, args) # /3 for optional args

  # Need to be able to download the content of a file at a particular
  # path. Should return bytes.
  def file_download(fs, path)       # /2 for normal use
  def file_download(fs, path, args) # /3 for optional args
end

defmodule Vaporator.CloudFs.Alias2to3 do

  @moduledoc """
  Convenience module for defining CloudFs protocols.

  For each of the protocol functions that take an optional args,
  provide an implementation of the arity /2 version that references an
  arity /3 version, passing an empty args map.
  
  """
  def list_folder(fs, path), do: list_folder(fs, path, %{})
  def get_metadata(fs, path), do: get_metadata(fs, path, %{})
  def file_download(fs, path), do: file_download(fs, path, %{})
end

defmodule Vaporator.CloudFs.Meta do
  @moduledoc """
  CloudFs file/folder (i.e. inode) metadata
  """
  # Every file on any file-system (Dropbox, GDrive, S3, etc.) should
  # have at least these attributes
  @enforce_keys [:type, :name, :path]
  defstruct [
    :type,                      # :file or :folder?

    :name,                      # file name (w/o path)

    :path,                      # path in file-system

    :modify_time,               # time of last modification (UTC)

    :create_time,               # time of creation (UTC)

    :meta                       # file-system-specific metadata term
                                # to be used internally by the
                                # particular file-system
  ]
end

