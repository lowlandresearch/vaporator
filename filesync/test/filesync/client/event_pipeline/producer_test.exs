# BDO: Most of these tests feel like we're unit-testing GenStage's
# innards. What am I missing here?

defmodule Filesync.Client.EventProducerTest do
  use ExUnit.Case, async: false
  alias Filesync.Client.EventProducer

  @test_event {:created, {"fake/", "fake/test.txt"}}

  setup_all do
    EventProducer.start_link()
    :ok
  end

  test "EventProducer started with correct state" do
    pid = Process.whereis(EventProducer)
    assert Process.alive?(pid)
    # The application starts EventConsumer with a demand of 2
    assert {queue, 2} = :sys.get_state(pid).state
  end

  test "enqueue api for an event" do
    response = EventProducer.enqueue(@test_event)

    assert response == :ok
  end

  test "handle_cast for enqueue an event" do
    test_event = {:modified, {"fake/", "fake/test.txt"}}

    {:noreply, _, {queue, 0}} =
      EventProducer.handle_cast(
        {:enqueue, test_event},
        {:queue.new(), 0}
      )

    {{:value, queued_event}, _} = :queue.out(queue)
    assert queued_event == test_event
  end

  test "dispatch single event when requested" do
    queue = :queue.in(@test_event, :queue.new())

    events_requested = 1

    {:noreply, events, _} =
      EventProducer.dispatch_events(
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
        {:created, {"fake/", "fake/test.txt"}},
        {:modified, {"fake/", "fake/test.txt"}},
        {:deleted, {"fake/", "fake/test.txt"}}
      ])

    events_requested = :queue.len(queue)

    {:noreply, events, _} =
      EventProducer.dispatch_events(
        queue,
        events_requested,
        []
      )

    events_received = length(events)
    assert events_received == events_requested
  end

  test "dispatch_events with an empty queue" do
    events_requested = 1

    {:noreply, events, {_, pending_demand}} =
      EventProducer.dispatch_events(
        :queue.new(),
        events_requested,
        []
      )

    assert events == []
    assert pending_demand == events_requested
  end
end
