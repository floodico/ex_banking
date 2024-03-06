defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

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
      on_exit(fn -> :sys.replace_state(ExBanking.AccountsManager, fn _ -> %{} end) end)
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

    test "returns error when arguments are not valid" do
      assert {:error, :wrong_arguments} = ExBanking.deposit("", 300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.deposit(nil, 300, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, -300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, "300", "EUR")
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, nil, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, 300, "")
      assert {:error, :wrong_arguments} = ExBanking.deposit(@deposit_user, 300, nil)
    end
  end

  describe "withdraw/3" do
    setup do
      :ok = ExBanking.create_user(@deposit_user)
      {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "EUR")
      {:ok, 500.0} = ExBanking.deposit(@deposit_user, 500, "USD")
      on_exit(fn -> :sys.replace_state(ExBanking.AccountsManager, fn _ -> %{} end) end)
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

    test "returns error when arguments are not valid" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw("", 300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(nil, 300, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, -300, "EUR")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, "300", "EUR")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, nil, "EUR")

      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, 300, "")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(@deposit_user, 300, nil)
    end
  end

  describe "get_balance/2" do
    setup do
      :ok = ExBanking.create_user(@deposit_user)
      on_exit(fn -> :sys.replace_state(ExBanking.AccountsManager, fn _ -> %{} end) end)
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
  end
end
