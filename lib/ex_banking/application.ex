defmodule ExBanking.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ExBanking.AccountsSupervisor, []},
      {Registry, [keys: :unique, name: ExBanking.AccountsRegistry]}
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
