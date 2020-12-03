defmodule Vaporator.Repo do
  use Ecto.Repo,
    otp_app: :vaporator,
    adapters: Application.get_env(:vaporator, __MODULE__)[:adapter]
end
