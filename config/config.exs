# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :vaporator, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:vaporator, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

config :logger,
  level: :info

# Providers:
# - :dropbox
#     - :dbx_api_url
#     - :dbx_content_url
# - TODO :onedrive
# - TODO :googledrive
config :vaporator, cloudfs_provider: :dropbox

# Dropbox global configurations
config :vaporator, dbx_api_url: "https://api.dropboxapi.com/2"
config :vaporator, dbx_content_url: "https://content.dropboxapi.com/2/"

# Each of the standard environment config files ({test,dev,prod}.exs)
# will import an "instance.exs" config that will NOT be part of the
# code distribution. It must be manually created for development as
# well as deployment.
# 
# ----------------------------------------------------------------------
# 
# Configurations that MUST be made either in test.exs, dev.exs,
# prod.exs, or instance.exs
# 
# ----------------------------------------------------------------------
#
# 
# config :vaporator, dbx_token: "dropbox_access_token" 
# config :vaporator, clientfs_sync_dirs: [
#   "/list", "/of", "/absolute", "/paths"
# ]
# config :vaporator, cloudfs_root: "/path/in/cloudfs/"
#

import_config "#{Mix.env()}.exs"


