defmodule BookBotWeb.Facebook.WebhookController do
  @moduledoc false

  use BookBotWeb, :controller

  alias BookBotWeb.Facebook.Webhook

  import Webhook, only: [verify_subscription: 1, verify_payload: 1]

  def verify(conn, params) do
    case verify_subscription(params) do
      {:ok, challenge} ->
        send_resp(conn, 200, challenge)

      :error ->
        send_resp(conn, 403, "")
    end
  end

  def process_events(conn, data) do
    with :ok <- verify_payload(conn),
         {:ok, _} <- data |> Webhook.Event.to_event() |> BookBot.Messaging.process_event() do
      send_resp(conn, 200, "")
    else
      _ ->
        send_resp(conn, 500, "")
    end
  end
end
