defmodule EightDCore.Crypto.Blake3 do
  @moduledoc """
  BLAKE3 hashing mechanism for content-addressed DAG nodes.
  Implemented using native Rustler NIF for max performance.
  """

  @doc """
  Hashes the given binary data using BLAKE3 Native.
  """
  @spec hash(binary()) :: String.t()
  def hash(data) when is_binary(data) do
    EightDCore.Native.hash_bytes(data)
  end

  @doc """
  Hashes an Erlang term (struct, map, etc) predictably.
  """
  @spec hash_term(any()) :: String.t()
  def hash_term(term) do
    term
    |> :erlang.term_to_binary()
    |> hash()
  end
end
