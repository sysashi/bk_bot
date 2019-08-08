defmodule BookBot do
  @moduledoc false

  ## Conversation setup

  def conversation_name(%{psid: psid}),
    do: {:via, Registry, {BookBot.ConversationRegistry, psid}}

  def default_conversation_commands() do
    %{
      show_book: &BookBot.GoodreadsClient.show_book/1,
      search_books: &BookBot.GoodreadsClient.search_books/1,
      send_message: &BookBot.FacebookClient.send_message/1,
      get_profile_fields: &BookBot.FacebookClient.get_profile_fields/2
    }
  end

  def process_event(%{psid: psid} = event) do
    case Registry.lookup(BookBot.ConversationRegistry, psid) do
      [{pid, _}] ->
        GenServer.cast(pid, {:new_event, event})
        {:ok, pid}

      _ ->
        DynamicSupervisor.start_child(
          BookBot.ConversationSupervisor,
          {BookBot.Conversation, {event, []}}
        )
    end
  end
end
