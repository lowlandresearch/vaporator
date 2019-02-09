defmodule Vaporator.ClientFs.EventProcessor do
  def start_link(event) do
    Task.start_link(fn ->
      Task.async(
        Vaporator.ClientFs.process_event(event)
      ) |> Task.await
    end)
  end
end