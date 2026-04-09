defmodule EightDCore.Crypto.Blake3Test do
  use ExUnit.Case, async: true
  alias EightDCore.Crypto.Blake3

  test "hash/1 generates a consistent 64-character BLAKE3 string" do
    result = Blake3.hash("test_payload")
    assert is_binary(result)
    assert String.length(result) == 64
    assert result == Blake3.hash("test_payload") # Idempotent
  end

  test "hash_term/1 handles Erlang structures robustly" do
    map_hash = Blake3.hash_term(%{foo: "bar"})
    assert String.length(map_hash) == 64
  end
end
