defmodule BookBot.MessagingTest do
  use ExUnit.Case, async: true

  alias BookBot.Messaging

  alias BookBotWeb.Facebook.Webhook.Event.{Postback, Message}

  setup do
    {:ok, conversation: %BookBot.Conversation{psid: "test", commands: %{}}}
  end

  describe "Conversation" do
    test "starts with command /start and greets user", c do
      conversation = expect_greeting(c.conversation)
      conversation = Messaging.handle_event(%Message{text: "/start"}, conversation)
      assert conversation.state == {:await_option, :search_by}
    end

    test "ignores events that are not being awited on", c do
      conversation = expect_greeting(c.conversation)

      conversation = Messaging.handle_event(%Message{text: "/start"}, conversation)
      assert conversation.state == {:await_option, :search_by}

      conversation = Messaging.handle_event(%Message{text: "test_input"}, conversation)
      assert conversation.state == {:await_option, :search_by}

      conversation = Messaging.handle_event(%Postback{payload: "testpayload"}, conversation)
      assert conversation.state == {:await_option, :search_by}
    end

    test "happy path is working", c do
      # start conversation
      conversation = expect_greeting(c.conversation)
      conversation = Messaging.handle_event(%Message{text: "/start"}, conversation)

      # ask what field to use for search (search by)
      conversation =
        expect_message_send(conversation, fn %{message: message} ->
          assert message.text =~ "Please type in"
          {:ok, %{}}
        end)

      conversation = Messaging.handle_event(selected_opt_event(:search_by, :title), conversation)

      # show matched books
      conversation =
        stub_command(
          conversation,
          :search_books,
          fn params ->
            assert params[:q] == "TestBookTitle"

            books =
              for i <- 1..10, do: %{average_rating: Enum.random(3..5), title: "TestBook-#{i}"}

            {:ok, books}
          end
        )

      conversation =
        expect_message_send(conversation, fn postback ->
          assert postback.message.attachment.payload.text =~ "Select a book"
          {:ok, %{}}
        end)

      conversation = Messaging.handle_event(text_input_event("TestBookTitle"), conversation)

      # let pick one and show result
      conversation =
        expect_message_send(conversation, fn postback ->
          assert postback.message.attachment.payload.text =~ ~r/(You should|Maybe)/
          {:ok, %{}}
        end)

      conversation = Messaging.handle_event(selected_opt_event(:books, 0), conversation)
      assert conversation.state == :end_conversation
    end
  end

  def selected_opt_event(key, value) do
    %Postback{payload: "set_option:#{key}:#{value}"}
  end

  def text_input_event(value) do
    %Message{text: value}
  end

  def expect_message_send(conversation, fun) do
    stub_command(
      conversation,
      :send_message,
      fn
        %{sender_action: _} ->
          :ok

        message ->
          fun.(message)
      end
    )
  end

  def expect_greeting(conversation) do
    conversation
    |> stub_command(
      :get_profile_fields,
      fn "test", "first_name" ->
        {:ok, %{"first_name" => "TestUser"}}
      end
    )
    |> stub_command(
      :send_message,
      fn msg ->
        assert msg.message.attachment.payload.text =~ "Hello TestUser, "
        {:ok, %{}}
      end
    )
  end

  def stub_command(%{commands: commands} = conversation, command, fun) do
    %{conversation | commands: Map.put(commands, command, fun)}
  end
end
