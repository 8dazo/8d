defmodule EightDCore.Crypto.Ed25519Test do
  use ExUnit.Case
  alias EightDCore.Crypto.Ed25519

  test "generate_keypair, sign, and verify" do
    {pub, priv} = Ed25519.generate_keypair()
    assert is_binary(pub)
    assert is_binary(priv)

    message = "Hello 8d swarm!"
    signature = Ed25519.sign(message, priv)

    assert Ed25519.verify(message, signature, pub)
    refute Ed25519.verify("Wrong message", signature, pub)
  end

  @tag timeout: 120_000
  test "benchmark operations" do
    {pub, priv} = Ed25519.generate_keypair()
    message = "Benchmark payload"
    
    start_time = :os.system_time(:millisecond)
    iterations = 20_000

    Enum.each(1..iterations, fn _ ->
      sig = Ed25519.sign(message, priv)
      true = Ed25519.verify(message, sig, pub)
    end)
    
    end_time = :os.system_time(:millisecond)
    elapsed = end_time - start_time
    
    # Approx 20k operations (40k total sign/verifies) should easily finish in under 2 seconds.
    IO.puts("\nEd25519 Benchmark: #{iterations} sig/verifies in #{elapsed}ms")
    assert elapsed < 5000
  end
end
