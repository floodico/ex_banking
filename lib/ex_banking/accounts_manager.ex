defmodule ExBanking.AccountsManager do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_user(user) do
    GenServer.call(__MODULE__, {:create_user, user})
  end

  def deposit(user, amount, currency) do
    GenServer.call(__MODULE__, {:deposit, user, amount, currency})
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:create_user, user}, _from, state) do
    if Map.has_key?(state, user) do
      {:reply, {:error, :user_already_exists}, state}
    else
      {:reply, :ok, Map.put(state, user, %{balance: %{}})}
    end
  end

  @impl true
  def handle_call({:deposit, user, amount, currency}, _from, state) do
    if Map.has_key?(state, user) do
      currency_amount = get_in(state, [user, :balance, currency]) || 0.0
      updated_currency_amount = currency_amount + amount

      {:reply, {:ok, updated_currency_amount |> Float.round(2)},
       put_in(state[user][:balance][currency], updated_currency_amount)}
    else
      {:reply, {:error, :user_does_not_exist}, state}
    end
  end
end