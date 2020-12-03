alias Vaporator.FileSystems

FileSystems.create_client(%{name: "test_client", ip_address: "192.168.1.2", os_type: "windows_xp"})
FileSystems.create_cloud(%{name: "dropbox", access_token: "123421652345"})
FileSystems.create_sync(%{client_id: 1, cloud_id: 1, client_base_path: "/chaz/", cloud_base_path: "/Backup/"})
FileSystems.create_file(%{sync_id: 1, client_path: "/chaz/fun/test.txt", client_hash: "123432421", cloud_path: "/Backup/chaz/fun/test.txt"})
