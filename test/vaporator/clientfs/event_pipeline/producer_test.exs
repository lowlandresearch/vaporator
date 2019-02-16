defmodule Vaporator.ClientFs.EventProducerTest do
  use ExUnit.Case, async: false

  @test_event {:created, "fake/test.txt"}

  setup_all do
    Vaporator.ClientFs.EventProducer.start_link()
    :ok
  end

  test "EventProducer started with correct state" do
    pid = Process.whereis(Vaporator.ClientFs.EventProducer)
    assert Process.alive?(pid)
    assert {queue, 0} = :sys.get_state(pid).state
  end

  test "enqueue an event" do
    response = Vaporator.ClientFs.EventProducer.enqueue(@test_event)

    assert response == :ok
  end

  test "handle_cast for enqueue an event" do
    {:noreply, _, {queue, 0}} =
      Vaporator.ClientFs.EventProducer.handle_cast(
        {:enqueue, @test_event},
        {:queue.new(), 0}
      )

    {{:value, queued_event}, _} = :queue.out(queue)
    assert queued_event == @test_event
  end

  test "handle_demand from consumer" do
    producer_state = :sys.get_state(Vaporator.ClientFs.EventProducer).state

    requested_events = 1

    {:noreply, events, _} =
      Vaporator.ClientFs.EventProducer.handle_demand(
        requested_events,
        producer_state
      )

    received_event = List.first(events)
    assert received_event == @test_event
  end

  test "dispatch single event when requested" do
    queue = :queue.in(@test_event, :queue.new())

    events_requested = 1

    {:noreply, events, _} =
      Vaporator.ClientFs.EventProducer.dispatch_events(
        queue,
        events_requested,
        []
      )

    received_event = List.first(events)
    assert received_event == @test_event
  end

  test "dispatch multiple events when requested" do
    queue =
      :queue.from_list([
        {:created, "fake/test.txt"},
        {:modified, "fake/test.txt"},
        {:deleted, "fake/test.txt"}
      ])

    events_requested = :queue.len(queue)

    {:noreply, events, _} =
      Vaporator.ClientFs.EventProducer.dispatch_events(
        queue,
        events_requested,
        []
      )

    events_received = length(events)
    assert events_received == events_requested
  end
end
