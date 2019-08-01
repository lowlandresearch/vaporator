defmodule Filesync.Settings.Cloud do
  alias Filesync.Cloud.Dropbox

  defstruct [provider: %Dropbox{}]
end