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

    test "provides a money format with 2-decimal precision" do
      assert {:ok, 300.0} = ExBanking.deposit(@deposit_user, 300.005, "EUR")
      assert {:ok, 800.01} = ExBanking.deposit(@deposit_user, 500.005, "EUR")
    end

    test "returns error when user does not exist" do
      :sys.replace_state(ExBanking.AccountsManager, fn _ -> %{} end)
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
end
