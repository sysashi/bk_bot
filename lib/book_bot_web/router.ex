defmodule BookBotWeb.Router do
  use BookBotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/facebook/webhook", BookBotWeb.Facebook, as: :facebook do
    pipe_through :api
    get "/", WebhookController, :verify
    post "/", WebhookController, :process_events
  end
end
