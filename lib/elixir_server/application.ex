defmodule ElixirServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("ELIXIR_SERVER_PORT") || "3000")
    children = [
      {KvStorage, %{}},
      {Task.Supervisor, name: ElixirServer.TaskSupervisor},
      {ElixirServer.Worker, [port]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
