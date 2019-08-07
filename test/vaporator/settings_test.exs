defmodule Vaporator.SettingsTest do
  use ExUnit.Case
  doctest Vaporator.Settings

  alias Vaporator.Settings

  @record_key Settings.defaults()
              |> Keyword.keys()
              |> List.first()

  @setting_key Keyword.fetch!(Settings.defaults(), @record_key)
              |> Keyword.keys()
              |> List.first()

  test "init default settings" do
    expected = Settings.defaults()
    Settings.init()
    actual = Settings.get()
    assert actual == expected
  end

  test "check if record exists" do
    actual = Settings.exists?(@record_key)
    assert actual == true
    actual = Settings.exists?(:willneverexist)
    asset actual == false
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

  test "get settings by record" do
    expected_record_keys = [@record_key]
    expected_setting_keys =
      Settings.defaults()
      |> Keyword.fetch!(@record_key)
      |> fn x -> [{@record_key, x}] end.()
      |> get_setting_keys()

    current_settings = Settings.get(@record_key)

    actual_record_keys = Keyword.keys(current_settings)
    actual_setting_keys = get_setting_keys(current_settings)
    assert actual_record_keys == expected_record_keys
    assert actual_setting_keys == expected_setting_keys
  end

  test "get setting by record and key" do
    assert {:ok, _} = Settings.get(@record_key, @setting_key)
    assert Settings.get(@record_key, :fake) == :error
  end

  test "get all settings with matching records" do
    assert Settings.get_by_key(@record_key) != []
    assert Settings.get_by_key(:fake) == :error
  end

  test "update a record's settings" do
    assert Settings.put(@record_key, @setting_key, :testing) == :ok

    expected = Keyword.replace!(Settings.defaults(), @record_key, [change: true])
    assert Settings.put(@record_key, expected) == :ok
    assert Settings.get!(@record_key) == expected

    expected = Keyword.replace!(Settings.defaults(), @record_key, [change: false])
    assert Settings.put(@record_key, expected, overwrite: false) == :noop
    assert Settings.put(@record_key, expected, overwrite: true) == :ok
  end

  test "check if required settings are not still default" do
    actual = Settings.set?(@record_key)
    assert actual == false

    actual = Settings.set?()
    assert actual == false

    generate_new_settings()

    actual = Settings.set?(@record_key)
    assert actual == true

    actual = Settings.set?()
    assert actual == true
  end

  def get_setting_keys(settings) do
    Enum.map(settings, fn {_, v} -> Keyword.keys(v) end)
  end

  def generate_new_settings do
    Enum.map(Settings.defaults(), &get_new_settings/1)
  end

  def generate_new_settings({key, settings}) do
    new_settings = Enum.map(settings, &generate_random_values/1)
    Settings.put(key, new_settings)
  end

  def generate_random_values({k, _}) do
    {k, :rand.normal()}
  end

end