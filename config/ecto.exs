import Config

config :vaporator,
  ecto_repos: [Vaporator.Repo]

database_name = "#{Mix.env()}.sqlite3"

database_path =
  if Mix.target() != :host do
    Path.join(["/", "root", database_name])
  else
    database_name
  end

config :vaporator, Vaporator.Repo,
  adapter: Sqlite.Ecto2,
  database: database_path
