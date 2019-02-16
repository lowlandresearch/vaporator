defmodule Vaporator.ClientFs.EventProducer do
  @moduledoc """
  Receives events from FileSystem and provides events
  to EventConsumer
  https://hexdocs.pm/gen_stage/GenStage.html
  """
  use GenStage
  require Logger

  def start_link(state \\ {:queue.new(), 0}) do
    Logger.info("#{__MODULE__} starting")
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    Logger.info("#{__MODULE__} queue initialized")
    {:producer, state}
  end

  #############
  # API
  #############

  @doc """
  Receives FileSystem events sent from EventMonitor, stores them
  in queue, and dispatches them to EventConsumer
  """
  def enqueue(event) do
    GenStage.cast(__MODULE__, {:enqueue, event})
  end

  @doc """
  Checks for event duplicates or conflicts to avoid unecessary CloudFs api
  calls

  Scenarios Checked:
    - Event already exists in queue
    - If :modified event, does a :created event for that file already exist

  Args:
    event (tuple)

  Returns:
    bool
  """
  def event_conflict?(event, queue) do
    case event do
      {:modified, path} ->
        :queue.member({:created, path}, queue) or :queue.member(event, queue)

      _ ->
        :queue.member(event, queue)
    end
  end

  @doc """
  Dispatches events to EventConsumer from EventProducer queue

  Args:
    queue (Erlang :queue)
    demand (Integer)
    events (List)

  Returns:
    noreply_callback (tuple):
      i.e. {:noreply, events, {queue, demand}}
  """
  def dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  def dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        # Callback for EventMonitor GenStage.call
        dispatch_events(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end

  #############
  # SERVER
  #############

  @doc """
  Receives and processes enqueue events sent from EventMonitor, stores them
  in queue, and dispatches them to EventConsumer
  """
  def handle_cast({:enqueue, event}, {queue, pending_demand}) do
    if not event_conflict?(event, queue) do
      new_queue = :queue.in(event, queue)
      Logger.info("#{__MODULE__} added event to queue")
      dispatch_events(new_queue, pending_demand, [])
    else
      {:noreply, [], {queue, pending_demand}}
    end
  end

  @doc """
  Receives demand from EventConsumer and dispatches events to satisfy demand
  """
  def handle_demand(incoming_demand, {queue, pending_demand}) do
    Logger.info("#{__MODULE__} dispatching events")
    dispatch_events(queue, pending_demand + incoming_demand, [])
  end
end
