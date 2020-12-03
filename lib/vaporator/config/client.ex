defmodule Vaporator.Config.Client do
  use Ecto.Schema
  import Ecto.Changeset

  @supported_os_types Application.get_env(:vaporator, :supported_os_types)

  schema "clients" do
    field(:name, :string)
    field(:ip_address, :string)
    field(:os_type, :string)
    field(:available, :boolean, default: true)

    timestamps()
  end

  def changeset(client, attrs \\ %{}) do
    client
    |> cast(attrs, [:name, :ip_address, :os_type, :available])
    |> validate_required([:name, :ip_address, :os_type])
    |> validate_inclusion(:os_type, @supported_os_types)
    |> unique_constraint(:ip_address)
  end

  def new do
    %__MODULE__{}
  end
end
