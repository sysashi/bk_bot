defmodule BookBot.GoodreadsClient do
  @moduledoc false

  import SweetXml

  def show_book(id, params \\ []) do
    url = build_url("/book/show.xml", Keyword.put(params, :id, id))

    case BookBot.HttpClient.Hackney.request(:get, url) do
      {:ok, %{body: xml, status_code: 200}} ->
        get_book = fn node, selector ->
          xpath(
            node,
            selector,
            id: ~x"./id/text()"s,
            title: ~x"./title/text()"s,
            ratings_count: ~x"./ratings_count/text()"i,
            average_rating: ~x"./average_rating/text()"f
          )
        end

        {:ok,
         Map.put(
           get_book.(xml, ~x".//book"),
           :similar_books,
           get_book.(xml, ~x".//book/similar_books/book"el)
         )}

      {_, resp} ->
        {:error, resp}
    end
  end

  def search_books(params) do
    case BookBot.HttpClient.Hackney.request(:get, build_url("/search/index.xml", params)) do
      {:ok, %{body: xml, status_code: 200}} ->
        books =
          xpath(
            xml,
            ~x"//work"l,
            ratings_count: ~x"./ratings_count/text()"i,
            average_rating: ~x"./average_rating/text()"f,
            id: ~x"./best_book/id/text()"s,
            title: ~x"./best_book/title/text()"s
          )

        {:ok, Enum.sort_by(books, & &1.average_rating, &>=/2)}

      {_, resp} ->
        {:error, resp}
    end
  end

  def build_url(path, params) do
    config = Application.get_env(:book_bot, :goodreads)
    params = Keyword.put(params, :key, config[:key])

    %{URI.parse(config[:url]) | query: URI.encode_query(params), path: path}
    |> to_string()
  end
end
