defmodule Filesync.Client.EventMonitorTest do
  use ExUnit.Case, async: true

  alias Filesync.Client.EventMonitor

  @sync_dirs SettingStore.get!(:client, :sync_dirs)

  setup_all do
    Filesync.Client.EventMonitor.start_link(["./test"])
    :ok
  end

  test "EventMonitor is running" do
    pid = Process.whereis(EventMonitor)
    assert Process.alive?(pid)
  end

  test "cache_client" do
    assert {:ok, _} = EventMonitor.cache_client(@sync_dirs)
    assert {:error, _} = EventMonitor.cache_client("/fake")
  end

  test "cache_cloud" do
    assert {:ok, _} = EventMonitor.cache_cloud(@sync_dirs)
    assert {:error, _} = EventMonitor.cache_cloud("/fake")
  end

end
