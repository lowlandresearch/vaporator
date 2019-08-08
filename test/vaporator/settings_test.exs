defmodule Vaporator.SettingsTest do
  use ExUnit.Case
  doctest Vaporator.Settings

  alias Vaporator.Settings

  setup_all do
    {:ok, [record_key: record_key(), setting_key: setting_key()]}
  end

  test "check if record exists", ctx do
    actual = Settings.exists?(ctx[:record_key])
    assert actual == true
    actual = Settings.exists?(:willneverexist)
    assert actual == false
  end

  test "get all settings" do
    expected_record_keys = Keyword.keys(Settings.defaults())
    expected_setting_keys = get_setting_keys(Settings.defaults())

    current_settings = Settings.get()

    actual_record_keys = Keyword.keys(current_settings)
    actual_setting_keys = get_setting_keys(current_settings)
    assert actual_record_keys == expected_record_keys
    assert actual_setting_keys == expected_setting_keys
  end

  test "get settings by record", ctx do
    assert {:ok, _} = Settings.get(ctx[:record_key])
  end

  test "get setting by record and key", ctx do
    assert {:ok, _} = Settings.get(ctx[:record_key], ctx[:setting_key])
    assert Settings.get(ctx[:record_key], :fake) == :error
  end

  test "update a record's settings", ctx do
    Settings.init()
    new_setting = generate_settings(ctx[:record_key])

    expected = :noop
    actual = Settings.put(ctx[:record_key], new_setting, overwrite: false)
    assert actual == expected

    expected = :ok
    actual = Settings.put(ctx[:record_key], new_setting, overwrite: true)
    assert actual == expected

    new_setting = generate_settings(ctx[:record_key])
    actual = Settings.put(ctx[:record_key], new_setting)
    assert actual == expected

    actual = Settings.put(ctx[:record_key], ctx[:setting_key], :testing)
    assert actual == expected
  end

  test "delete a record", ctx do
    expected = :ok
    actual = Settings.delete(ctx[:record_key])
    assert actual == expected
  end

  test "reset settings to default", ctx do
    expected =
      Settings.defaults()
      |> Keyword.fetch!(ctx[:record_key])

    generate_settings()
    actual = Settings.get!(ctx[:record_key])
    assert actual != expected

    Settings.reset()
    actual = Settings.get!(ctx[:record_key])
    assert actual == expected
  end

  test "check if required settings are not still default", ctx do
    Settings.reset()
    
    actual = Settings.set?()
    assert actual == false

    actual = Settings.set?(ctx[:record_key])
    assert actual == false

    generate_settings()

    actual = Settings.set?(ctx[:record_key])
    assert actual == true

    actual = Settings.set?()
    assert actual == true
  end

  def get_first_key(keyword) do
    keyword
    |> Keyword.keys()
    |> List.first()
  end

  def record_key do
    Settings.defaults()
    |> get_first_key()
  end

  def setting_key do
    Settings.defaults()
    |> Keyword.fetch!(record_key())
    |> get_first_key()
  end

  def get_setting_keys(settings) do
    Enum.map(settings, fn {_, v} -> Keyword.keys(v) end)
  end

  def generate_settings do
    Settings.defaults()
    |> Keyword.keys()
    |> Enum.map(fn k -> {k, generate_settings(k)} end)
    |> Enum.map(fn {k, v} -> Settings.put(k, v) end)
  end

  def generate_settings(record_key) do
    Settings.defaults()
    |> Enum.filter(fn {k, _} -> k == record_key end)
    |> Enum.map(fn {_, v} -> generate_random_values(v) end)
    |> List.flatten()
  end

  def generate_random_values(settings) do
    Enum.map(settings, fn {k, _} -> {k, :rand.normal()} end)
  end

end