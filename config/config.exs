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

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"

config :vaporator, api_url: "https://api.dropboxapi.com/2"
config :vaporator, content_url: "https://content.dropboxapi.com/2/"

config :vaporator, watch_dirs: ["C:/dropbox"]

config :vaporator, clientfs_path: "C:/dropbox/"
config :vaporator, cloudfs_path: "/vaporator/test/"

config :vaporator, test_dir: "/vaporator/test/"
config :vaporator, test_file: "test.txt"

config :exvcr, [
  vcr_cassette_library_dir: "test/vaporator/fixture/vcr_cassettes",
  custom_cassette_library_dir: "test/vaporator/fixture/custom_cassettes",
  filter_sensitive_data: [
    [pattern: "Bearer .+", placeholder: "<<DROPBOX_ACCESS_TOKEN>>"]
  ],
  filter_url_params: false,
  filter_request_headers: [],
  response_headers_blacklist: ["X-Dropbox-Request-Id"]
]

config :logger,
  level: :info
