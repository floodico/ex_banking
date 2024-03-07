defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  alias ExBanking.Accounts
  alias ExBanking.AccountsRegistry
  alias ExBanking.AccountsSupervisor

  describe "create_user/1" do
    test "creates user successfully" do
      assert :ok = ExBanking.create_user("Jack")
    end

    test "returns error when user already exists" do
      assert :ok = ExBanking.create_user("Pedro")
      assert {:error, :user_already_exists} = ExBanking.create_user("Pedro")
    end

    test "returns error when user argument is not valid" do
      assert {:error, :wrong_arguments} = ExBanking.create_user("")
      assert {:error, :wrong_arguments} = ExBanking.create_user(nil)
    end
  end

  @deposit_user "Luis"
  describe "deposit/3" do
    setup do
      :ok = ExBanking.create_user(@deposit_user)
      on_exit(fn -> remove_user(@deposit_user) end)
    end

    test "makes successful deposits in different currencies" do
      assert {:ok, 300.0} = ExBanking.deposit(@deposit_user, 300, "EUR")
      assert {:ok, 300.0} = ExBanking.deposit(@deposit_user, 300, "USD")
    end

    test "increases deposit balance for different currencies" do
      assert {:ok, 300.0} = ExBanking.deposit(@deposit_user, 300, "EUR")
      assert {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "USD")

      assert {:ok, 600.0} = ExBanking.deposit(@deposit_user, 300, "EUR")
      assert {:ok, 900.0} = ExBanking.deposit(@deposit_user, 400, "USD")
    end

    test "returns a money format with 2-decimal precision" do
      assert {:ok, 300.0} = ExBanking.deposit(@deposit_user, 300.005, "EUR")
      assert {:ok, 800.01} = ExBanking.deposit(@deposit_user, 500.005, "EUR")
    end

    test "returns error when user does not exist" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("Absent", 300, "EUR")
    end

    test "returns error when depositing zero amount" do
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, 0, "EUR")
    end

    test "returns error when arguments are not valid" do
      assert {:error, :wrong_arguments} = ExBanking.deposit("", 300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.deposit(nil, 300, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, -300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, "300", "EUR")
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, nil, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, 300, "")
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, 300, nil)
    end

    test "returns error when too many transactions for user in the process" do
      :ok = simulate_user_transactions_limit(@deposit_user)

      assert {:error, :too_many_requests_to_user} = ExBanking.deposit(@deposit_user, 300, "EUR")
    end
  end

  describe "withdraw/3" do
    setup do
      :ok = ExBanking.create_user(@deposit_user)
      {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "EUR")
      {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "USD")
      on_exit(fn -> remove_user(@deposit_user) end)
    end

    test "makes successful withdrawals in different currencies" do
      assert {:ok, 200.0} = ExBanking.withdraw(@deposit_user, 300, "EUR")
      assert {:ok, 200.0} = ExBanking.withdraw(@deposit_user, 300, "USD")
    end

    test "continues to make withdrawals in different currencies" do
      assert {:ok, 200.0} = ExBanking.withdraw(@deposit_user, 300, "EUR")
      assert {:ok, 200.0} = ExBanking.withdraw(@deposit_user, 300, "USD")

      assert {:ok, 100.0} = ExBanking.withdraw(@deposit_user, 100, "EUR")
      assert {:ok, 0.0} = ExBanking.withdraw(@deposit_user, 100, "EUR")
      assert {:ok, 0.0} = ExBanking.withdraw(@deposit_user, 200, "USD")
    end

    test "returns a money format with 2-decimal precision" do
      assert {:ok, 199.99} = ExBanking.withdraw(@deposit_user, 300.009, "EUR")
      assert {:ok, 99.98} = ExBanking.withdraw(@deposit_user, 100.009, "EUR")
    end

    test "returns error when user does not exist" do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("Absent", 300, "EUR")
    end

    test "returns error when user doesn't have enough currency amount" do
      assert {:error, :not_enough_money} = ExBanking.withdraw(@deposit_user, 900, "EUR")
      assert {:error, :not_enough_money} = ExBanking.withdraw(@deposit_user, 600, "EUR")

      assert {:error, :not_enough_money} = ExBanking.withdraw(@deposit_user, 100, "UAH")
      assert {:error, :not_enough_money} = ExBanking.withdraw(@deposit_user, 100, "USDT")
    end

    test "returns error when withdrawing zero amount" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, 0, "EUR")
    end

    test "returns error when arguments are not valid" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw("", 300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(nil, 300, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, -300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, "300", "EUR")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, nil, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, 300, "")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, 300, nil)
    end

    test "returns error when too many transactions for user in the process" do
      :ok = simulate_user_transactions_limit(@deposit_user)

      assert {:error, :too_many_requests_to_user} = ExBanking.withdraw(@deposit_user, 300, "EUR")
    end
  end

  describe "get_balance/2" do
    setup do
      :ok = ExBanking.create_user(@deposit_user)
      on_exit(fn -> remove_user(@deposit_user) end)
    end

    test "returns the initial currency balance" do
      assert {:ok, 0.0} = ExBanking.get_balance(@deposit_user, "EUR")
      assert {:ok, 0.0} = ExBanking.get_balance(@deposit_user, "USD")
    end

    test "returns the currency balance after deposits" do
      {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "EUR")
      {:ok, 800.0} = ExBanking.deposit(@deposit_user, 800, "USD")

      assert {:ok, 500.0} = ExBanking.get_balance(@deposit_user, "EUR")
      assert {:ok, 800.0} = ExBanking.get_balance(@deposit_user, "USD")
    end

    test "returns the currency balance after withdrawals" do
      {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "EUR")
      {:ok, 800.0} = ExBanking.deposit(@deposit_user, 800, "USD")
      {:ok, 400.0} = ExBanking.withdraw(@deposit_user, 100, "EUR")
      {:ok, 700.0} = ExBanking.withdraw(@deposit_user, 100, "USD")

      assert {:ok, 400.0} = ExBanking.get_balance(@deposit_user, "EUR")
      assert {:ok, 700.0} = ExBanking.get_balance(@deposit_user, "USD")
    end

    test "returns a money format with 2-decimal precision" do
      {:ok, 500.56} = ExBanking.deposit(@deposit_user, 500.555, "EUR")
      assert {:ok, 500.56} = ExBanking.get_balance(@deposit_user, "EUR")
    end

    test "returns error when user does not exist" do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("Absent", "EUR")
    end

    test "returns error when arguments are not valid" do
      assert {:error, :wrong_arguments} = ExBanking.get_balance("", "EUR")
      assert {:error, :wrong_arguments} = ExBanking.get_balance(nil, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.get_balance(@deposit_user, "")
      assert {:error, :wrong_arguments} = ExBanking.get_balance(@deposit_user, nil)
    end

    test "returns error when too many transactions for user in the process" do
      :ok = simulate_user_transactions_limit(@deposit_user)

      assert {:error, :too_many_requests_to_user} = ExBanking.get_balance(@deposit_user, "EUR")
    end
  end

  @sender "Lukas"
  @receiver "Peter"
  describe "send/4" do
    setup do
      :ok = ExBanking.create_user(@sender)
      :ok = ExBanking.create_user(@receiver)

      on_exit(fn ->
        remove_user(@sender)
        remove_user(@receiver)
      end)
    end

    test "makes a transfer successfully" do
      {:ok, 500.0} = ExBanking.deposit(@sender, 500, "EUR")
      assert {:ok, 0.0, 500.0} = ExBanking.send(@sender, @receiver, 500, "EUR")
    end

    test "returns error when some of users does not exist" do
      assert {:error, :sender_does_not_exist} = ExBanking.send("Absent", @receiver, 500, "EUR")
      assert {:error, :sender_does_not_exist} = ExBanking.send("Absent1", "Absent2", 500, "EUR")
      assert {:error, :receiver_does_not_exist} = ExBanking.send(@sender, "Absent2", 500, "EUR")
    end

    test "returns error when sender doesn't have enough currency amount" do
      assert {:error, :not_enough_money} = ExBanking.send(@sender, @receiver, 900, "EUR")
    end

    test "returns error when transferring zero amount" do
      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @receiver, 0, "EUR")
    end

    test "returns an error when trying to transfer to itself" do
      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @sender, 300, "EUR")
    end

    test "returns error when arguments are not valid" do
      assert {:error, :wrong_arguments} = ExBanking.send("", nil, 300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.send(nil, "", 300, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @receiver, -300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @receiver, "300", "EUR")
      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @receiver, nil, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @receiver, 300, "")
      assert {:error, :wrong_arguments} = ExBanking.send(@sender, @receiver, 300, nil)
    end

    test "returns error when too many transactions for sender in the process" do
      :ok = simulate_user_transactions_limit(@sender)

      assert {:error, :too_many_requests_to_sender} =
               ExBanking.send(@sender, @receiver, 300, "EUR")
    end

    test "returns error when too many transactions for receiver in the process" do
      :ok = simulate_user_transactions_limit(@receiver)

      assert {:error, :too_many_requests_to_receiver} =
               ExBanking.send(@sender, @receiver, 300, "EUR")
    end
  end

  defp remove_user(user) do
    [{pid, _}] = Registry.lookup(AccountsRegistry, user)
    :ok = DynamicSupervisor.terminate_child(AccountsSupervisor, pid)
  end

  defp simulate_user_transactions_limit(user) do
    {:ok, pid} = Accounts.lookup(user)
    true = :erlang.suspend_process(pid)
    Enum.each(1..10, fn _ -> send(pid, :hello) end)
  end
end
