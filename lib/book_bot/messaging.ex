defmodule BookBot.Messaging do
  @moduledoc false

  alias BookBotWeb.Facebook.Webhook.Event

  ## Conversation setup

  def conversation_name(%{psid: psid}), do: {:via, Registry, {BookBot.ConversationRegistry, psid}}

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

  def default_conversation_commands() do
    %{
      show_book: &BookBot.GoodreadsClient.show_book/1,
      search_books: &BookBot.GoodreadsClient.search_books/1,
      send_message: &BookBot.FacebookClient.send_message/1,
      get_profile_fields: &BookBot.FacebookClient.get_profile_fields/2
    }
  end

  ## Conversation flow

  def handle_event(%Event.Referral{ref: "init"}, state),
    do: dispatch(:greeting, state)

  def handle_event(%Event.Message{text: "/start"}, state),
    do: dispatch(:greeting, state)

  def handle_event(%Event.Postback{payload: "init"}, state),
    do: dispatch({:show_options, :search_by}, state)

  def handle_event(
        %Event.Postback{payload: "set_option:" <> opt},
        %{state: {:await_option, key}} = state
      ) do
    string_key = Atom.to_string(key)

    case String.split(opt, ":") do
      [^string_key, value] ->
        dispatch({:set_option, key, value}, state)

      _ ->
        state
    end
  end

  def handle_event(%Event.Message{text: input}, %{state: {:await_input, key}} = conv) do
    dispatch({:set_input, key, input}, conv)
  end

  def handle_event(_, state), do: state

  ## Actions

  def dispatch(:greeting, conversation) do
    greeting =
      case conversation.commands.get_profile_fields.(conversation.psid, "first_name") do
        {:ok, %{"first_name" => first_name}} ->
          "Hello #{first_name}, "

        {:error, _} ->
          "Hi, "
      end

    dispatch({:show_options, :search_by}, assign(conversation, :greeting, greeting))
  end

  def dispatch({:show_options, :search_by}, conversation) do
    greeting = Map.get(conversation.assigns, :greeting, "")

    postback =
      postback_button(
        greeting <> "do you want to search book by Title or Goodreads ID?",
        Enum.map(search_options(), fn opt ->
          %{payload: "set_option:search_by:#{opt.by}", title: opt.text}
        end)
      )

    send_message(conversation, build_message(conversation.psid, postback))

    %{conversation | state: {:await_option, :search_by}}
  end

  def dispatch({:set_option, :search_by, value}, conversation) do
    opt = Enum.find(search_options(), &(&1.by == String.to_existing_atom(value)))

    options =
      (conversation.assigns[:options] || %{})
      |> Map.put(:search_by, opt[:by] || value)

    message =
      conversation.psid
      |> build_message(%{text: "Please type in #{String.downcase(opt.text)}"})

    send_message(conversation, message)

    conversation
    |> Map.put(:state, {:await_input, :search_param})
    |> assign(:options, options)
  end

  def dispatch({:set_input, :search_param, value}, conversation) do
    send_message(conversation, sender_action(conversation.psid, :typing_on))

    books =
      case Map.get(conversation.assigns.options, :search_by, :title) do
        :title ->
          {:ok, result} = conversation.commands.search_books.(q: value, field: :title)
          result

        :goodreads_id ->
          {:ok, result} = conversation.commands.show_book.(value)
          {similar_books, requested_book} = Map.pop(result, :similar_books, [])
          [requested_book | similar_books]
      end

    send_message(conversation, sender_action(conversation.psid, :typing_off))

    dispatch({:show_options, :books}, assign(conversation, :books, books))
  end

  # 3 is a max number of buttons for regular postback button template
  def dispatch({:show_options, :books}, conversation) do
    matched_books =
      conversation.assigns.books
      |> Enum.take(3)
      |> Enum.with_index(0)
      |> Enum.map(fn {book, index} ->
        %{title: book.title, payload: "set_option:books:#{index}"}
      end)

    postback =
      if Enum.empty?(matched_books) do
        postback_button("Sorry, nothing were found", [try_again_button()])
      else
        postback_button("Select a book please", matched_books)
      end

    send_message(conversation, build_message(conversation.psid, postback))

    %{conversation | state: {:await_option, :books}}
  end

  def dispatch({:set_option, :books, index}, conversation) do
    send_message(conversation, sender_action(conversation.psid, :typing_on))

    selected_book = conversation.assigns.books |> Enum.at(String.to_integer(index))
    suggestion = mighty_ai_suggestion(selected_book)

    send_message(conversation, sender_action(conversation.psid, :typing_off))

    message =
      build_message(
        conversation.psid,
        postback_button(suggestion, [try_again_button()])
      )

    send_message(conversation, message)
    %{conversation | state: :end_conversation}
  end

  def search_options() do
    [
      %{text: "Goodreads ID", by: :goodreads_id},
      %{text: "Title", by: :title}
    ]
  end

  # Utils

  defp try_again_button() do
    %{payload: "init", title: "try again"}
  end

  defp assign(state, key, value),
    do: %{state | assigns: Map.put(state.assigns, key, value)}

  defp send_message(conversation, message), do: conversation.commands.send_message.(message)

  # oh yeah
  def mighty_ai_suggestion(book, sleep? \\ Mix.env() != :test) do
    # processing :)
    if sleep?, do: Enum.random(200..400) |> Process.sleep()

    if book.average_rating >= 4.2 do
      "You should definitely buy this book!"
    else
      "Maybe it is better to skip this one."
    end
  end

  ## Various messages api

  def postback_button(text, buttons) do
    %{
      attachment: %{
        type: "template",
        payload: %{
          template_type: "button",
          text: text,
          buttons: Enum.map(buttons, &Map.put_new(&1, :type, "postback"))
        }
      }
    }
  end

  def build_message(psid, message) do
    %{
      messaging_type: "RESPONSE",
      recipient: %{
        id: psid
      },
      message: message
    }
  end

  def sender_action(psid, action) do
    %{
      recipient: %{
        id: psid
      },
      sender_action: action
    }
  end
end
