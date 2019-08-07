import Config

config :vaporator, cloud_root: "/vaporator/test/"

config :vaporator, client_sync_dirs: []

config :vaporator, test_dir: "/vaporator/test/"
config :vaporator, test_file: "test.txt"

config :logger, level: :warn

config :exvcr,
  vcr_cassette_library_dir: "test/vaporator/fixture/vcr_cassettes",
  custom_cassette_library_dir: "test/vaporator/fixture/custom_cassettes",
  filter_sensitive_data: [
    [pattern: "Bearer .+", placeholder: "<<DROPBOX_ACCESS_TOKEN>>"]
  ],
  filter_url_params: false,
  filter_request_headers: [],
  response_headers_blacklist: ["X-Dropbox-Request-Id"]
