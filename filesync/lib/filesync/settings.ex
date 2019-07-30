defmodule Filesync.Settings.Client do
  defstruct sync_dirs: [], poll_interval: 30000
end

defmodule Filesync.Settings.Cloud do

  alias Filesync.Cloud.Dropbox

  defstruct [provider: %Dropbox{}]
end

defmodule Filesync.Settings do

  alias Filesync.Settings.{Client, Cloud}

  def init do
    SettingStore.create(:client, %Client{})
    SettingStore.create(:cloud, %Cloud{})
  end
end