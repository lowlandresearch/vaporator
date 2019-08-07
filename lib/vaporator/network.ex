defmodule Vaporator.Network do
  alias Vaporator.Network.{Ethernet, Wireless}

  def interface_up?(interface) do
    case Nerves.Network.status(interface) do
      %{is_up: true, operstate: :down} -> false
      %{is_up: false} -> false
      _ -> true
    end
  end

  def up? do
    Ethernet.up?() and
      Wireless.up?() and
      internet_reachable?()
  end

  def internet_reachable? do
    match?(
      {:ok, {:hostent, 'google.com', [], :inet, 4, _}},
      :inet_res.gethostbyname('google.com')
    )
  end
end
