defmodule BookBotWeb.Facebook.Webhook do
  @moduledoc false

  def to_events(%{"object" => "page", "entry" => entries}) do
    Enum.map(entries, fn %{"messaging" => [messaging]} ->
      BookBotWeb.Facebook.Webhook.Event.messaging_to_event(messaging)
    end)
  end

  def keep_raw_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.private[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end

  def verify_subscription(request, opts \\ [])

  def verify_subscription(
        %{
          "hub.mode" => "subscribe",
          "hub.challenge" => challenge,
          "hub.verify_token" => to_verify
        },
        opts
      ) do
    verifcation_token =
      opts
      |> config_with_defaults()
      |> Keyword.fetch!(:webhook_verification_token)

    if secure_check(to_verify, verifcation_token) do
      {:ok, challenge}
    else
      :error
    end
  end

  def verify_subscription(_, _), do: :error

  @signature_key "x-hub-signature"
  def verify_payload(conn, opts \\ []) do
    app_secret =
      opts
      |> config_with_defaults()
      |> Keyword.fetch!(:app_secret)

    with {:ok, signature} <- fetch_signature(conn, @signature_key),
         payload <- Map.fetch!(conn.private, :raw_body),
         calculated_signature <- calc_signature(payload, app_secret),
         true <- secure_check(signature, calculated_signature) do
      :ok
    else
      _ ->
        :error
    end
  end

  def calc_signature(data, app_secret) do
    :crypto.hmac(:sha, app_secret, data) |> Base.encode16(case: :lower)
  end

  def fetch_signature(conn, key) do
    case Plug.Conn.get_req_header(conn, key) do
      ["sha1=" <> sig] ->
        {:ok, sig}

      _ ->
        :error
    end
  end

  def secure_check(left, right) do
    if byte_size(left) == byte_size(right) do
      secure_check(left, right, 0) == 0
    else
      false
    end
  end

  defp secure_check(<<left, left_rest::binary>>, <<right, right_rest::binary>>, acc) do
    import Bitwise, only: [|||: 2, ^^^: 2]
    secure_check(left_rest, right_rest, acc ||| left ^^^ right)
  end

  defp secure_check(<<>>, <<>>, acc) do
    acc
  end

  defp config_with_defaults(opts) do
    app_config = Application.get_env(:book_bot, :facebook, [])
    Keyword.merge(app_config, opts)
  end
end
