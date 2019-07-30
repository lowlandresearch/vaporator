defmodule Vaporator.Settings do

  alias Vaporator.Settings.{Client, Cloud}
  alias Filesync.Cloud.Dropbox

  @doc """
  Initializes default settings
  """
  def init do
    init_settings(
      :client,
      %Client{sync_dirs: [], poll_interval: 30000}
    )

    init_settings(
      :cloud,
      %Cloud{root_path: "", provider: %Dropbox{access_token: ""}}
    )
  end

  defp init(table, value) do
    if not exists?(table) do
      PersistentStorage.put(
        :settings,
        table,
        value
      )
      {:ok, :setting_initalized}
    end
    {:ok, :setting_exists}
  end

  defp exist?(table) do
    case PersistentStorage.get(:settings, table) do
      nil -> false
      _ -> true
    end
  end
  
  @doc """
  Retrives current settings
  """
  def get(table) do
    PersistentStorage.get(:settings, table)
  end

  def get(table, key) do
    setting = get(table)
    Map.fetch(key)
  end

  def get!(table, key) do
    {:ok, value} = get(table, key)
    value
  end

  @doc """
  Updates settings

  Returns `:ok`
  """
  def update(table, key, value) do
    setting = PersistentStorage.get(:settings, table)
    new_setting = Map.replace!(setting, key, value)
    update(table, new_setting)
  end

  defp update(table, setting) do
    PersistentStorage.put(:settings, table, setting)
  end

end

defmodule Vaporator.Settings.Client do
  @enforce_keys [:sync_dirs, :poll_interval]
  defstruct [:sync_dirs, :poll_interval]
end

defmodule Vaporator.Settings.Cloud do
  @enforce_keys [:root_path, :provider]
  defstruct [:root_path, :provider]
end

defmodule Vaporator.Settings.Network do
  @enforce_keys [:ssid, :psk, :key_mgmt, :connected]
  defstruct [:ssid, :psk, :key_mgmt, :connected]
end