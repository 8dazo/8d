defmodule EightDCore.Crypto.Ed25519 do
  @moduledoc """
  Ed25519 signatures for agent identity verification via Erlang :crypto.
  """

  @doc """
  Generates a new Ed25519 keypair.
  Returns {public_key, private_key}.
  """
  def generate_keypair do
    :crypto.generate_key(:eddsa, :ed25519)
  end

  @doc """
  Signs a message (usually a hash) using the private key.
  """
  @spec sign(binary(), binary()) :: binary()
  def sign(message, private_key) do
    :crypto.sign(:eddsa, :none, message, [private_key, :ed25519])
  end

  @doc """
  Verifies a signature using the public key.
  """
  @spec verify(binary(), binary(), binary()) :: boolean()
  def verify(message, signature, public_key) do
    :crypto.verify(:eddsa, :none, message, signature, [public_key, :ed25519])
  end
end
