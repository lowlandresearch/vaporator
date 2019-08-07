# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :vaporator, target: Mix.target()

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

config :vaporator, dbx_api_url: "https://api.dropboxapi.com/2"
config :vaporator, dbx_content_url: "https://content.dropboxapi.com/2/"

if Mix.env() == :test do
  import_config "#{Mix.env()}.exs"
end

if Mix.target() != :host do
  import_config "target.exs"
end
