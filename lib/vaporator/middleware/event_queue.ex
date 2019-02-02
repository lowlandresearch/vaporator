defmodule Vaporator.EventQueue do
  use Agent

  def start_link(state \\ :queue.new) do
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  def enqueue(event) do
    queue = __MODULE__.queue
    if not :queue.member(event, queue) do
      Agent.update(
        __MODULE__,
        fn x -> :queue.in(event, x) end
      )
    end
  end

  def dequeue do
    state = __MODULE__.queue
    case :queue.out(state) do
      {{_, next_event}, new_queue} ->
        Agent.update(__MODULE__, fn _x -> new_queue end)
        next_event

      {:empty, _} -> {:empty, "EventQueue is empty"}
    end
  end

  def queue do
    Agent.get(__MODULE__, fn state -> state end)
  end

end