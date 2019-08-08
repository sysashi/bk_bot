use Mix.Config

config :book_bot, BookBotWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
