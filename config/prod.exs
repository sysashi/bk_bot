use Mix.Config

host = System.get_env("HOST") || "bk_bot.sysashi.space"
port = String.to_integer(System.get_env("PORT") || "4000")

config :book_bot, BookBotWeb.Endpoint,
  url: [host: host, port: 443],
  http: [:inet6, port: port]

config :logger, level: :info
