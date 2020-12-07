# Add Toolshed helpers to the IEx session
use Toolshed

if RingLogger in Application.get_env(:logger, :backends, []) do
  IO.puts """
  RingLogger is collecting log messages from Elixir and Linux. To see the
  messages, either attach the current IEx session to the logger:

    RingLogger.attach

  or print the next messages in the log:

    RingLogger.next
  """
end

Application.put_env(:elixir, :ansi_enabled, true)
IEx.configure(
  colors: [enabled: true],
  default_prompt: [
    "\e[G",    # ANSI CHA, move cursor to column 1
    :magenta,
    "%prefix", # IEx prompt variable
    ">",       # plain string
    :reset
  ] |> IO.ANSI.format |> IO.chardata_to_string
)
