defmodule Vaporator.ClientFs.EventMonitorTest do
  use ExUnit.Case, async: false

  @test_event {:file_event, :none, {"fake/test.txt", [:created]}}

  setup_all do
    Vaporator.ClientFs.EventMonitor.Supervisor.start_link()
    :ok
  end

  test "EventMonitor.Supervisor started with EventMonitor" do
    pid = Process.whereis(Vaporator.ClientFs.EventMonitor.Supervisor)
    assert Process.alive?(pid)

    pid = Process.whereis(Vaporator.ClientFs.EventMonitor)
    assert Process.alive?(pid)
  end

  test "file event received" do
    paths = Vaporator.ClientFs.get_sync_dirs()
    assert {:noreply, paths} = Vaporator.ClientFs.EventMonitor.handle_info(@test_event, paths)
  end

  test "file event queued in EventProducer" do
    {:ok, pid} = Vaporator.ClientFs.EventProducer.start_link()

    paths = Vaporator.ClientFs.get_sync_dirs()
    Vaporator.ClientFs.EventMonitor.handle_info(@test_event, paths)

    {queue, _} = :sys.get_state(pid).state
    {{:value, queued_event}, _} = :queue.out(queue)
    assert queued_event == {:created, "fake/test.txt"}
  end
end
