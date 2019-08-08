use Mix.Config

config :phoenix, :json_library, Jason

config :book_bot, BookBotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MOS8Nb2HFInyhQqOGcsh2GzYT7qJiUVuIBX4YRG/I8cbiZFNEVIlodgTefWXNKCn",
  render_errors: [view: BookBotWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: BookBot.PubSub, adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :book_bot, :goodreads,
  key: System.get_env("GOODREADS_KEY"),
  url: "https://www.goodreads.com/"

config :book_bot, :facebook,
  graph_url: "https://graph.facebook.com/v4.0/",
  app_id: System.get_env("FACEBOOK_APP_ID"),
  app_secret: System.get_env("FACEBOOK_APP_SECRET"),
  page_access_token: System.get_env("FACEBOOK_PAGE_ACCESS_TOKEN"),
  webhook_verification_token: System.get_env("FACEBOOK_WEBHOOK_VERIFICATION_TOKEN")

import_config "#{Mix.env()}.exs"
