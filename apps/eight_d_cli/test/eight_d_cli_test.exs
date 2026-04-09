defmodule EightDCliTest do
  use ExUnit.Case
  doctest EightDCli

  test "greets the world" do
    assert EightDCli.hello() == :world
  end
end
