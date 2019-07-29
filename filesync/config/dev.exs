import Config

config :filesync, cloud_root: "/filesync/test/"

config :filesync, client_sync_dirs: []

import_config "instance.exs"