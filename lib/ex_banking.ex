defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.

  This module provides functions for basic banking operations, including user creation,
  deposit, withdrawal, balance inquiry, and fund transfers.
  """

  alias ExBanking.Accounts
  alias ExBanking.MoneyBalance
  alias ExBanking.InputParams

  @doc """
  Create a new user account.

  ## Parameters

  - `user` (String.t()): The username for the new account.

  ## Returns

  - `:ok`: The user account was successfully created.
  - `{:error, :wrong_arguments | :user_already_exists}`: An error indicating invalid arguments or an existing user with the same name.
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with :ok <- InputParams.validate(:create_user, user) do
      Accounts.create(user)
    end
  end

  @doc """
  Deposit funds into a user account.

  ## Parameters

  - `user` (String.t()): The username for the account.
  - `amount` (number): The amount to deposit.
  - `currency` (String.t()): The currency of the deposit.

  ## Returns

  - `{:ok, new_balance :: number}`: The deposit was successful, and the new account balance.
  - `{:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}`: An error indicating invalid arguments, a non-existent user, or too many transaction requests.
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    with :ok <- InputParams.validate(:deposit, {user, amount, currency}),
         {:ok, pid} <- Accounts.lookup(user),
         :ok <- Accounts.allow_transaction_for_user(pid) do
      MoneyBalance.deposit(user, amount, currency)
    end
  end

  @doc """
  Withdraw funds from a user account.

  ## Parameters

  - `user` (String.t()): The username for the account.
  - `amount` (number): The amount to withdraw.
  - `currency` (String.t()): The currency of the withdrawal.

  ## Returns

  - `{:ok, new_balance :: number}`: The withdrawal was successful, and the new account balance.
  - `{:error, :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user}`: An error indicating invalid arguments, a non-existent user, insufficient funds, or too many transaction requests.
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    with :ok <- InputParams.validate(:withdraw, {user, amount, currency}),
         {:ok, pid} <- Accounts.lookup(user),
         :ok <- Accounts.allow_transaction_for_user(pid) do
      MoneyBalance.withdraw(user, amount, currency)
    end
  end

  @doc """
  Get the balance of a user account.

  ## Parameters

  - `user` (String.t()): The username for the account.
  - `currency` (String.t()): The currency of the balance.

  ## Returns

  - `{:ok, balance :: number}`: The current account balance.
  - `{:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}`: An error indicating invalid arguments, a non-existent user, or too many transaction requests.
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    with :ok <- InputParams.validate(:get_balance, {user, currency}),
         {:ok, pid} <- Accounts.lookup(user),
         :ok <- Accounts.allow_transaction_for_user(pid) do
      MoneyBalance.get_balance(user, currency)
    end
  end

  @doc """
  Send funds from one user account to another.

  ## Parameters

  - `from_user` (String.t()): The username of the sender.
  - `to_user` (String.t()): The username of the receiver.
  - `amount` (number): The amount to send.
  - `currency` (String.t()): The currency of the transfer.

  ## Returns

  - `{:ok, from_user_balance :: number, to_user_balance :: number}`: The transfer was successful, and the new balances of the sender and receiver.
  - `{:error, :wrong_arguments | :not_enough_money | :sender_does_not_exist | :receiver_does_not_exist | :too_many_requests_to_sender | :too_many_requests_to_receiver}`: An error indicating invalid arguments, insufficient funds, non-existent sender or receiver, or too many transaction requests.
  """
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
  def send(from_user, to_user, amount, currency) do
    with :ok <- InputParams.validate(:send, {from_user, to_user, amount, currency}),
         {_, {:ok, sender_pid}} <- {:sender_lookup, Accounts.lookup(from_user)},
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
end
