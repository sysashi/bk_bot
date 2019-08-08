defmodule BookBotWeb.Facebook.Webhook.Event do
  @moduledoc false

  # get latest entry, that's would be ok for our use case
  def to_event(%{"object" => "page", "entry" => entries}) do
    %{"messaging" => [messaging]} =
      entries
      |> Enum.sort_by(& &1["timestamp"])
      |> List.first()

    psid = get_in(messaging, ["sender", "id"])
    page_id = get_in(messaging, ["recipient", "id"])

    %{messaging_to_event(messaging) | psid: psid, page_id: page_id}
  end

  defmodule Message do
    defstruct [:psid, :page_id, :text]
  end

  defmodule Postback do
    defstruct [:psid, :page_id, :payload]
  end

  defmodule Referral do
    defstruct [:psid, :page_id, :ref]
  end

  def messaging_to_event(%{"postback" => postback}) do
    %Postback{
      payload: postback["payload"]
    }
  end

  def messaging_to_event(%{"message" => message}) do
    %Message{
      text: message["text"]
    }
  end

  def messaging_to_event(%{"referral" => referral}) do
    %Referral{
      ref: referral["ref"]
    }
  end
end
