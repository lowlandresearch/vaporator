use Mix.Config

config :filesync, cloudfs_root: "/filesync/test/"

config :filesync, clientfs_sync_dirs: []

import_config "instance.exs"



