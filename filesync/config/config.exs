# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :filesync, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:filesync, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

# Providers:
# - :dropbox
#     - :dbx_api_url
#     - :dbx_content_url
# - TODO :onedrive
# - TODO :googledrive

# Dropbox global configurations
config :filesync, dbx_api_url: "https://api.dropboxapi.com/2"
config :filesync, dbx_content_url: "https://content.dropboxapi.com/2/"

if Mix.env() == :test do
  import_config "#{Mix.env()}.exs"
end