defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.Accounts
  alias ExBanking.MoneyBalance

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) and user != "" do
    Accounts.create(user)
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and user != "" and is_number(amount) and amount > 0 and
             is_binary(currency) and currency != "" do
    with {:ok, pid} <- Accounts.lookup(user),
         :ok <- Accounts.allow_transaction_for_user(pid) do
      MoneyBalance.deposit(user, amount, currency)
    else
      error -> error
    end
  end

  def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and user != "" and is_number(amount) and amount > 0 and
             is_binary(currency) and currency != "" do
    with {:ok, pid} <- Accounts.lookup(user),
         :ok <- Accounts.allow_transaction_for_user(pid) do
      MoneyBalance.withdraw(user, amount, currency)
    else
      error -> error
    end
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency)
      when is_binary(user) and user != "" and is_binary(currency) and currency != "" do
    with {:ok, pid} <- Accounts.lookup(user),
         :ok <- Accounts.allow_transaction_for_user(pid) do
      MoneyBalance.get_balance(user, currency)
    else
      error -> error
    end
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and from_user != "" and is_binary(to_user) and to_user != "" and
             from_user != to_user and is_number(amount) and amount > 0 and is_binary(currency) and
             currency != "" do
    with {_, {:ok, sender_pid}} <- {:sender_lookup, Accounts.lookup(from_user)},
         {_, {:ok, receiver_pid}} <- {:receiver_lookup, Accounts.lookup(to_user)},
         {_, :ok} <- {:sender_req_check, Accounts.allow_transaction_for_user(sender_pid)},
         {_, :ok} <- {:receiver_req_check, Accounts.allow_transaction_for_user(receiver_pid)},
         {:ok, from_user_balance} <- MoneyBalance.withdraw(from_user, amount, currency),
         {:ok, to_user_balance} <- MoneyBalance.deposit(to_user, amount, currency) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:sender_lookup, _} -> {:error, :sender_does_not_exist}
      {:receiver_lookup, _} -> {:error, :receiver_does_not_exist}
      {:sender_req_check, _} -> {:error, :too_many_requests_to_sender}
      {:receiver_req_check, _} -> {:error, :too_many_requests_to_receiver}
      error -> error
    end
  end

  def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}
end
