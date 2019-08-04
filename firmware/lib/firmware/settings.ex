defmodule Firmware.Settings do
  @default_settings [
    wireless: [ssid: nil, psk: nil, key_mgmt: :NONE]
  ]

  def init do
    Enum.map(
      @default_settings,
      fn {k, v} ->
        SettingStore.put(k, v, overwrite: false)
      end
    )
  end

  def set? do
    SettingStore.set?(@default_settings)
  end

  def get do
    @default_settings
    |> Keyword.keys()
    |> SettingStore.get_by_keys()
  end

  def get(setting) do
    SettingStore.get(setting)
  end

  def put(setting, value) do
    SettingStore.put(setting, value)
  end
end
