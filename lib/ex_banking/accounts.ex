defmodule ExBanking.Accounts do
  @moduledoc "Accounts context"

  alias ExBanking.AccountsRegistry
  alias ExBanking.AccountsSupervisor

  @spec exists?(user :: String.t()) :: boolean()
  def exists?(user) do
    case Registry.lookup(AccountsRegistry, user) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  @spec create(user :: String.t()) :: :ok | {:error, :user_already_exists}
  def create(user) do
    case AccountsSupervisor.start_child(user) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end
end
