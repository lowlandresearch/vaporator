defprotocol Vaporator.CloudFs do
  @doc """
  Protocol for the most basic set of Cloud file-system operations

  Impls must implement the following functions:

  - list_folder
  - get_metadata
  - file_download
  - file_upload
  - ...

  """

  # TODO: Documentation
  def get_path(fs, local_path, cloudfs_root)

  # Need to be able to get the contents of a folder.
  #
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - path (binary): Path of folder on cloud file system to list
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. In a perfect world, this would be
  #     unnecessary, but "let it fail..." and all that.
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFs.ResultsMeta}
  #     or
  #   {:error, {:path_not_found, path error (binary)}
  #     or 
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def list_folder(fs, path, args \\ %{})

  # Need to be able to get the metadata of an object at a particular
  # path.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - path (binary): Path of file/folder on cloud file system to get
  #     metadata for
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFS.Meta}
  #     or
  #   {:error, {:path_not_found, path error (binary)}
  #     or 
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def get_metadata(fs, path, args \\ %{})

  # Need to be able to get the binary content of a file at a particular
  # path.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - path (binary): Path of file on cloud file system to download
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFs.FileContent}
  #     or
  #   {:error, {:path_not_found, path error (binary)}
  #     or 
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def file_download(fs, path, args \\ %{})

  # Need to be able to upload binary content of a file on the local
  # file system to a particular path on the cloud file system.
  # 
  # The file should always be transferred and should overwrite
  # whatever is (might be) already there.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - local_path (binary): Path of file on local file system to upload
  # - fs_path (binary): Path on cloud file system to place uploaded
  #     content. If this path ends with a "/" then it should be
  #     treated as a directory in which to place the local_path
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFs.Meta}
  #     or
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def file_upload(fs, local_path, fs_path, args \\ %{})

  # Need to be able to update binary content of a file on the cloud
  # file system to the version on the local file system.
  #
  # In the case of file_upload, the file is always transferred. In the
  # case of file_update, the file transfer only happens if the cloud
  # content is different from the local content.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - local_path (binary): Path of file on local file system to upload
  # - fs_path (binary): Path on cloud file system to place uploaded
  #     content. If this path ends with a "/" then it should be
  #     treated as a directory in which to place the local_path
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFs.Meta}
  #     or
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def file_update(fs, local_path, fs_path, args \\ %{})

  # Need to be able to remove a file or folder on the cloud file
  # system.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - path (binary): Path on cloud file system to remove. 
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFs.FileContent}
  #     or
  #   {:error, {:path_not_found, path error (binary)}
  #     or 
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def file_remove(fs, path, args \\ %{})
  def folder_remove(fs, path, args \\ %{})

  # Need to be able to copy one file in the cloud file system to
  # another place in the cloud file system.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - from_path (binary): Path of file/folder on cloud file system to
  #     copy
  # - to_path (binary): Path of file/folder on cloud file system to
  #     place the copied file. If this path ends in a "/", then it is
  #     treated as a directory into which the file should be copied.
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFS.Meta}
  #     or
  #   {:error, {:path_not_found, path error (binary)}
  #     or 
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def file_copy(dbx, from_path, to_path, args \\ %{})

  # Need to be able to move one file in the cloud file system to
  # another place in the cloud file system.
  # 
  # Args:
  # - fs (Vaporator.CloudFs impl): Cloud file system
  # - from_path (binary): Path of file/folder on cloud file system to
  #     move
  # - to_path (binary): Path of file/folder on cloud file system to
  #     place the moved file. If this path ends in a "/", then it is
  #     treated as a directory into which the file should be moved.
  # - args (Map): File-system-specific arguments to pass to the
  #     underlying subsystem. 
  # 
  # Returns:
  #   {:ok, Vaporator.CloudFS.Meta}
  #     or
  #   {:error, {:path_not_found, path error (binary)}
  #     or 
  #   {:error, {:bad_decode, decode error (any)}
  #     or 
  #   {:error, {:bad_status, {:status_code, code (int)}, JSON (Map)}}
  #     or 
  #   {:error, {:unhandled_status, {:status_code, code (int)}, body (binary)}}
  def file_move(dbx, from_path, to_path, args \\ %{})
end

defmodule Vaporator.CloudFs.Meta do
  @moduledoc """
  CloudFs file/folder (i.e. inode) metadata
  """
  # Every file on any file-system (Dropbox, GDrive, S3, etc.) should
  # have at least these attributes
  @enforce_keys [:type, :path]
  defstruct [
    # :file, :folder, or :none?
    :type,
    # file name (w/o path)
    :name,
    # path in file-system
    :path,
    # time of last modification (UTC)
    :modify_time,
    # time of creation (UTC)
    :create_time,
    # file-system-specific metadata term
    :meta
    # to be used internally by the
    # particular file-system (i.e. the
    # implementation of the CloudFs
    # protocol)
  ]
end

defmodule Vaporator.CloudFs.ResultsMeta do
  @moduledoc """
  CloudFs result set/list metadata.

  Keeps track of a list of results that matter (usually file/folder
  metadata), but also keeps a reference to the original
  file-system-specific result meta object for use later by the
  particular cloud file system.

  E.g. Dropbox needs the list_folder metadata (specifically, the
  "cursor" and "has_more" values) for pagination.

  Some file systems might have results metadata, some might not. In
  the case of not, then the metadata field (meta:) has a default value
  of an empty map.

  """
  @enforce_keys [:results]
  defstruct results: [],

            # List of CloudFs.Meta objects

            # File-system-specific metadata for this
            meta: %{}

  # result set
end

defmodule Vaporator.CloudFs.FileContent do
  @moduledoc """
  CloudFs file content struct

  Basically a thin type wrapping the Map data returned by HTTPoison's
  HTTP methods (POST generally)

  """
  defstruct content: "",

            # Binary data from the body

            # Header data returned by the HTTP
            headers: %{}

  # response
end
