defmodule Vaporator.Client.EventMonitorTest do
  use ExUnit.Case, async: true

  alias Vaporator.{Settings, Client.EventMonitor}

  @sync_dirs Settings.get!(:client, :sync_dirs)

  test "EventMonitor is running" do
    pid = Process.whereis(Client.EventMonitor)
    assert Process.alive?(pid)
  end

  test "cache_client" do
    assert {:ok, _} = Client.EventMonitor.cache_client(@sync_dirs)
    assert {:error, _} = Client.EventMonitor.cache_client("/fake")
  end

  test "cache_cloud" do
    assert {:ok, _} = Client.EventMonitor.cache_cloud(@sync_dirs)
    assert {:error, _} = Client.EventMonitor.cache_cloud("/fake")
  end
end
