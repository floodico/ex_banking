defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) and user != "" do
    ExBanking.AccountsManager.create_user(user)
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and user != "" and is_number(amount) and amount >= 0 and
             is_binary(currency) and currency != "" do
    ExBanking.AccountsManager.deposit(user, amount, currency)
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
      when is_binary(user) and user != "" and is_number(amount) and amount >= 0 and
             is_binary(currency) and currency != "" do
    ExBanking.AccountsManager.withdraw(user, amount, currency)
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency)
      when is_binary(user) and user != "" and is_binary(currency) and currency != "" do
    ExBanking.AccountsManager.get_balance(user, currency)
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
  def send(from_user, to_user, amount, currency) do
    {:ok, 100.0, 100.0}
  end
end
