defmodule MicroBankTest do
  use ExUnit.Case
  doctest MicroBank

  setup do
    {:ok, pid} = MicroBank.start_link(%{"user1" => 100})
    %{pid: pid}
  end

  test "devolver saldo actual", %{pid: pid} do
    assert MicroBank.ask(pid, "user1") == {:ok, 100}
  end

  test "depositar cantidad en la cuenta", %{pid: pid} do
    assert MicroBank.deposit(pid, "user1", 50) == {:ok, 150}
    assert MicroBank.ask(pid, "user1") == {:ok, 150}
  end

  test "retirar cantidad de la cuenta", %{pid: pid} do
    assert MicroBank.ask(pid, "user1") == {:ok, 100}
    assert MicroBank.withdraw(pid, "user1", 50) == {:ok, 50}
  end

  test "retirada con saldo insuficiente de la cuenta", %{pid: pid} do
    assert MicroBank.withdraw(pid, "user1", 200) == {:error}
    assert MicroBank.ask(pid, "user1") == {:ok, 100}
  end
end
