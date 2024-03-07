defmodule ExBanking.Accounts do
  @moduledoc "Accounts context"

  alias ExBanking.AccountsRegistry
  alias ExBanking.AccountsSupervisor

  @spec lookup(user :: String.t()) :: {:ok, pid()} | {:error, :user_does_not_exist}
  def lookup(user) do
    case Registry.lookup(AccountsRegistry, user) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :user_does_not_exist}
    end
  end

  @spec create(user :: String.t()) :: :ok | {:error, :user_already_exists}
  def create(user) do
    case AccountsSupervisor.start_child(user) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  @spec allow_transaction_for_user(pid :: pid) :: :ok | {:error, :too_many_requests_to_user}
  def allow_transaction_for_user(pid) do
    case Process.info(pid, :message_queue_len) do
      {:message_queue_len, requests} when requests < 10 -> :ok
      _ -> {:error, :too_many_requests_to_user}
    end
  end
end
