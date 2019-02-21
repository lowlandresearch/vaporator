defmodule Vaporator.ClientFs.EventMonitorTest do
  use ExUnit.Case, async: true

  @test_event {:file_event, :none, {"fake/test.txt", [:created]}}

  setup_all do
    Vaporator.ClientFs.EventMonitor.start_link(["./test"])
    :ok
  end

  test "EventMonitor is running" do
    pid = Process.whereis(Vaporator.ClientFs.EventMonitor)
    assert Process.alive?(pid)
  end

  test "file event received and handled" do
    assert {:noreply, paths} = Vaporator.ClientFs.EventMonitor.handle_info(
      @test_event, Vaporator.ClientFs.sync_dirs
    )
  end

  test "file event queued in EventProducer" do
    {:ok, pid} = Vaporator.ClientFs.EventProducer.start_link()

    Vaporator.ClientFs.EventMonitor.handle_info(
      @test_event, Vaporator.ClientFs.sync_dirs
    )

    {queue, _} = :sys.get_state(pid).state
    {{:value, queued_event}, _} = :queue.out(queue)
    assert queued_event == {:created, "fake/test.txt"}
  end
end
