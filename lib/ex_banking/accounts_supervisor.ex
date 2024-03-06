defmodule ExBanking.AccountsSupervisor do
  use DynamicSupervisor

  alias ExBanking.MoneyBalance

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(user) do
    DynamicSupervisor.start_child(__MODULE__, {MoneyBalance, [name: user]})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
