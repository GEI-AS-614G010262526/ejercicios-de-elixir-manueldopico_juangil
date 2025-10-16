defmodule MicroBankTest do
  use ExUnit.Case
  doctest MicroBank

  test "greets the world" do
    assert MicroBank.hello() == :world
  end
end
