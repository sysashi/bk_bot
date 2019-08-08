defmodule BookBot.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task, &BookBot.FacebookClient.setup_basic_greeting/0},
      {Registry, keys: :unique, name: BookBot.ConversationRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: BookBot.ConversationSupervisor},
      BookBotWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: BookBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    BookBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
