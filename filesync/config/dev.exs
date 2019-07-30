import Config

config :filesync, cloud_root: "/vaporator/test/"

config :filesync, client_sync_dirs: []

import_config "instance.exs"