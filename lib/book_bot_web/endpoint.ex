defmodule BookBotWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :book_bot

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {
      BookBotWeb.Facebook.Webhook,
      :keep_raw_body,
      []
    }

  plug BookBotWeb.Router
end
