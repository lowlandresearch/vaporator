defprotocol Vaporator.Cloud do
  @doc "Convenience API for Cloud file system operations"
  def list_folder(auth, path)
  def get_metadata(auth, path, args)
end
