defmodule Vaporator.Client.EventMonitorTest do
  use ExUnit.Case, async: true

  alias Vaporator.{Settings, Client.EventMonitor, Cloud.Dropbox}

  @test_path "/tmp/vaporator"
  @cloud Application.get_env(:vaporator, :cloud)

  setup do
    File.mkdir(@test_path)
    Settings.reset()
    Settings.put(
      :cloud,
      :provider,
      %Dropbox{
        access_token: Keyword.get(@cloud, :access_token),
        root_path: Keyword.get(@cloud, :root_path)
      }
    )

    on_exit fn ->
      File.rm_rf!(@test_path)
    end

    {:ok, [path: @test_path]}
  end

  test "EventMonitor is running" do
    pid = Process.whereis(EventMonitor)
    assert Process.alive?(pid)
  end

  test "cache_client", ctx do
    assert {:ok, _} = EventMonitor.cache_client(ctx[:path])
    assert {:error, _} = EventMonitor.cache_client("/fake")
  end

  test "cache_cloud", ctx do
    assert {:ok, _} = EventMonitor.cache_cloud(ctx[:path])
    assert {:error, _} = EventMonitor.cache_cloud("/fake")
  end
end
