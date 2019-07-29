use Mix.Config

config :filesync, cloud_root: "/vaporator/test/"

config :filesync, client_sync_dirs: []

config :filesync, test_dir: "/vaporator/test/"
config :filesync, test_file: "test.txt"

config :logger, level: :warn

config :exvcr,
  vcr_cassette_library_dir: "test/filesync/fixture/vcr_cassettes",
  custom_cassette_library_dir: "test/filesync/fixture/custom_cassettes",
  filter_sensitive_data: [
    [pattern: "Bearer .+", placeholder: "<<DROPBOX_ACCESS_TOKEN>>"]
  ],
  filter_url_params: false,
  filter_request_headers: [],
  response_headers_blacklist: ["X-Dropbox-Request-Id"]

import_config "instance.exs"
