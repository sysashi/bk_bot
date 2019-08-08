defmodule BookBot.FacebookClient do
  @moduledoc false

  ## Resources

  def get_profile_fields(psid, fields) do
    request(:get, psid, "", %{fields: fields})
  end

  def set_messenger_profile_properties(data, params \\ %{}) do
    request(:post, "me/messenger_profile", data, params)
  end

  def send_message(message, params \\ %{}) when is_map(message) do
    request(:post, "me/messages", message, params)
  end

  def request(method, path, body, params, opts \\ []) do
    opts =
      Application.get_env(:book_bot, :facebook, [])
      |> Keyword.merge(opts)

    graph_url = Keyword.fetch!(opts, :graph_url)
    page_acess_token = Keyword.fetch!(opts, :page_access_token)
    params = Map.put_new(params, :access_token, page_acess_token)

    http_client = Keyword.get(opts, :http_client, BookBot.HttpClient.Hackney)

    http_client.request(
      method,
      build_url(graph_url, path, params),
      Jason.encode!(body),
      default_headers()
    )
    |> handle_response()
  end

  def handle_response({:ok, %{status_code: status, body: body}}) when status in 200..299 do
    Jason.decode(body)
  end

  # lets consider codes >= 300 as errors
  def handle_response({_, reason}) do
    {:error, reason}
  end

  def build_url(graph_url, path, params) do
    graph_uri = URI.parse(graph_url)
    path = Path.join(graph_uri.path, path)
    query = URI.encode_query(params)

    URI.to_string(%{graph_uri | path: path, query: query})
  end

  defp default_headers() do
    [{"content-type", "application/json"}]
  end

  def setup_basic_greeting(params \\ %{}) do
    set_messenger_profile_properties(
      %{
        get_started: %{
          payload: :init
        },
        greeting: [
          %{locale: :default, text: "Hello {{user_first_name}}"}
        ]
      },
      params
    )
  end
end
