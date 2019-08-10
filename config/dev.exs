use Mix.Config

config :book_bot, BookBotWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
