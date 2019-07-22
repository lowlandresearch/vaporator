defmodule Filesync.ClientFs.EventMonitorTest do
  use ExUnit.Case, async: true

  alias Filesync.ClientFs.EventMonitor

  @sync_dirs Filesync.ClientFs.sync_dirs()

  setup_all do
    Filesync.ClientFs.EventMonitor.start_link(["./test"])
    :ok
  end

  test "EventMonitor is running" do
    pid = Process.whereis(EventMonitor)
    assert Process.alive?(pid)
  end

  test "cache_clientfs" do
    assert {:ok, _} = EventMonitor.cache_clientfs(@sync_dirs)
    assert {:error, _} = EventMonitor.cache_clientfs("/fake")
  end

  test "cache_cloudfs" do
    assert {:ok, _} = EventMonitor.cache_cloudfs(@sync_dirs)
    assert {:error, _} = EventMonitor.cache_cloudfs("/fake")
  end

end
