defmodule Vaporator.EventQueue do
  use Agent

  def start_link(state \\ :queue.new) do
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @doc """
  Adds new event to queue
  """
  def enqueue(event) do
    if not event_conflict?(event) do
      Agent.update(
        __MODULE__,
        fn x -> :queue.in(event, x) end
      )
    end
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
  def event_conflict?(event) do
    state = __MODULE__.queue
    case event do
      {:modified, path} ->
        :queue.member({:created, path}, state)
      _ ->
        :queue.member(event, state)
    end
  end

  @doc """
  Removes next event from queue

  Returns:
    event (tuple)
  """
  def dequeue do
    state = __MODULE__.queue
    case :queue.out(state) do
      {{_, next_event}, new_state} ->
        Agent.update(__MODULE__, fn _x -> new_state end)
        next_event

      {:empty, _} -> {:empty, "EventQueue is empty"}
    end
  end

  @doc """
  Shows the current queue

  Returns:
    queue (:queue): Erlang queue containing all queued events
  """
  def queue do
    Agent.get(__MODULE__, fn state -> state end)
  end

  @doc """
  Provides a way to view number of events in the queue

  Returns:
    queue_length (integer): Number of items currently in queue
  """
  def length do
    Agent.get(__MODULE__, fn state -> :queue.len(state) end)
  end

end