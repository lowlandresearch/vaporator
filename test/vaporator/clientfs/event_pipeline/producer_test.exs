# BDO: Most of these tests feel like we're unit-testing GenStage's
# innards. What am I missing here?

defmodule Vaporator.ClientFs.EventProducerTest do
  use ExUnit.Case, async: false

  @test_event {:created, {"fake/", "fake/test.txt"}}

  # Since the tests are done with a running Application, why are we
  # starting up another EventProducer?
  # 
  setup_all do
    Vaporator.ClientFs.EventProducer.start_link()
    :ok
  end

  test "EventProducer started with correct state" do
    pid = Process.whereis(Vaporator.ClientFs.EventProducer)
    assert Process.alive?(pid)

    # If the Application callback line in mix.exs is commented out,
    # this works. If it is uncommented (i.e. if the Application is
    # allowed to start prior to testing), then this fails with:
    #
    # code:  assert {queue, 0} = :sys.get_state(pid).state()
    # right: {{[], []}, 2}
    assert {queue, 0} = :sys.get_state(pid).state
  end

  test "enqueue api for an event" do
    response = Vaporator.ClientFs.EventProducer.enqueue(@test_event)

    assert response == :ok
  end

  test "handle_cast for enqueue an event" do
    test_event = {:modified, {"fake/", "fake/test.txt"}}

    {:noreply, _, {queue, 0}} =
      Vaporator.ClientFs.EventProducer.handle_cast(
        {:enqueue, test_event},
        {:queue.new(), 0}
      )

    {{:value, queued_event}, _} = :queue.out(queue)
    assert queued_event == test_event
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

    # If the Application callback line in mix.exs is commented out,
    # this works. If it is uncommented (i.e. if the Application is
    # allowed to start prior to testing), then this fails with:
    #
    # code:  assert received_event == @test_event
    # left:  nil
    # right: {:created, {"fake/", "fake/test.txt"}}
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
        {:created, {"fake/", "fake/test.txt"}},
        {:modified, {"fake/", "fake/test.txt"}},
        {:deleted, {"fake/", "fake/test.txt"}}
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

  test "dispatch_events with an empty queue" do
    events_requested = 1

    {:noreply, events, {_, pending_demand}} =
      Vaporator.ClientFs.EventProducer.dispatch_events(
        :queue.new(),
        events_requested,
        []
      )

    assert events == []
    assert pending_demand == events_requested
  end
end
