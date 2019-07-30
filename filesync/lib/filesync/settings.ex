defmodule Filesync.Settings.Client do
  defstruct sync_dirs: [], poll_interval: 30000
end

defmodule Filesync.Settings.Cloud do
  alias Filesync.Cloud.Dropbox

  defstruct [
      root_path: nil,
      provider: %Dropbox{access_token: nil}
    ]
end

defmodule Filesync.Settings do

  alias Filesync.Settings.{Client, Cloud}

  def init do
    SettingStore.create(:client, %Client{})
    SettingStore.create(:cloud, %Cloud{})
  end
end



# defmodule Filesync.Settings.Cloud do

# end