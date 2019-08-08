defmodule BookBot.Conversation do
  @moduledoc false

  import BookBot.Messaging, only: [handle_event: 2, conversation_name: 1]

  use GenServer, restart: :transient

  def start_link({event, _} = args) do
    GenServer.start_link(__MODULE__, args, name: conversation_name(event))
  end

  defstruct state: nil,
            psid: nil,
            events: [],
            assigns: %{},
            commands: BookBot.default_conversation_commands()

  def init({event, params}) do
    {:ok, struct(__MODULE__, params), {:continue, {:init, event}}}
  end

  def handle_continue({:init, event}, conversation) do
    {:noreply, handle_event(event, %{conversation | events: [event], psid: event.psid})}
  end

  def handle_cast({:new_event, event}, conversation) do
    new_state = handle_event(event, conversation)
    new_state = %{new_state | events: [event | conversation.events]}

    case new_state do
      %{state: :end_conversation} ->
        {:stop, :normal, new_state}

      _ ->
        {:noreply, new_state}
    end
  end
end
