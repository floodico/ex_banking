defmodule ExBanking.InputParams do
  @moduledoc """
  Helper functions for input parameters validation
  """

  @type action :: :create_user | :deposit | :withdraw | :get_balance | :send

  defguard is_user(user) when is_binary(user) and user != ""
  defguard is_amount(amount) when is_number(amount) and amount > 0
  defguard is_currency(currency) when is_binary(currency) and currency != ""

  @spec validate(action :: action, params :: any) :: :ok | {:error, :wrong_arguments}
  def validate(:create_user, user) when is_user(user),
    do: :ok

  def validate(:deposit, {user, amount, currency})
      when is_user(user) and is_amount(amount) and is_currency(currency),
      do: :ok

  def validate(:withdraw, {user, amount, currency})
      when is_user(user) and is_amount(amount) and is_currency(currency),
      do: :ok

  def validate(:get_balance, {user, currency}) when is_user(user) and is_currency(currency),
    do: :ok

  def validate(:send, {sender, receiver, amount, currency})
      when is_user(sender) and is_user(receiver) and sender != receiver and is_amount(amount) and
             is_currency(currency),
      do: :ok

  def validate(_, _), do: {:error, :wrong_arguments}
end
