defmodule ExBanking.MoneyBalance do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_name(opts[:name]))
  end

  def deposit(user, amount, currency) do
    user |> via_name() |> GenServer.call({:deposit, amount, currency})
  end

  def withdraw(user, amount, currency) do
    user |> via_name() |> GenServer.call({:withdraw, amount, currency})
  end

  def get_balance(user, currency) do
    user |> via_name() |> GenServer.call({:get_balance, currency})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:deposit, amount, currency}, _from, balance) do
    currency_amount = Map.get(balance, currency, 0.0)
    updated_currency_amount = currency_amount + amount

    {:reply, {:ok, updated_currency_amount |> format_amount()},
     Map.put(balance, currency, updated_currency_amount)}
  end

  @impl true
  def handle_call({:withdraw, amount, currency}, _from, balance) do
    currency_amount = Map.get(balance, currency, 0.0)

    if currency_amount > 0 and currency_amount >= amount do
      updated_currency_amount = currency_amount - amount

      {:reply, {:ok, updated_currency_amount |> format_amount()},
       Map.put(balance, currency, updated_currency_amount)}
    else
      {:reply, {:error, :not_enough_money}, balance}
    end
  end

  @impl true
  def handle_call({:get_balance, currency}, _from, balance) do
    currency_amount = Map.get(balance, currency, 0.0)

    {:reply, {:ok, currency_amount |> format_amount()}, balance}
  end

  defp via_name(user) do
    {:via, Registry, {ExBanking.AccountsRegistry, user}}
  end

  defp format_amount(amount) when is_float(amount), do: Float.round(amount, 2)

  defp format_amount(amount) when is_integer(amount), do: Float.round(amount * 1.0, 2)
end
