defmodule EightDCore.MerkleDAG.Node do
  @moduledoc """
  Defines an immutable, content-addressed node in the Merkle-DAG.
  """

  alias EightDCore.Crypto.Blake3
  alias EightDCore.CRDT.VectorClock

  @type t :: %__MODULE__{
          hash: String.t() | nil,
          payload: any(),
          parents: [String.t()],
          signature: binary() | nil,
          agent_id: String.t(),
          vector_clock: VectorClock.t(),
          timestamp: pos_integer()
        }

  defstruct [
    :hash,
    :payload,
    parents: [],
    signature: nil,
    agent_id: "",
    vector_clock: %{},
    timestamp: 0
  ]

  @doc """
  Constructs a new Node.
  Note: This does not generate the signature. The signature must be applied
  separately, after which the node can be considered finalized.
  """
  @spec new(any(), [String.t()], String.t(), VectorClock.t()) :: t()
  def new(payload, parents, agent_id, vector_clock) do
    node = %__MODULE__{
      payload: payload,
      parents: Enum.sort(parents), # Sort parents for deterministic hashing
      agent_id: agent_id,
      vector_clock: vector_clock,
      timestamp: :os.system_time(:millisecond)
    }

    hash = compute_hash(node)
    %{node | hash: hash}
  end

  @doc """
  Computes the BLAKE3 hash of the node.
  The hash incorporates payload, parents, agent_id, clock, and timestamp,
  but excludes the signature and the hash itself.
  """
  @spec compute_hash(t()) :: String.t()
  def compute_hash(%__MODULE__{} = node) do
    data_to_hash = %{
      payload: node.payload,
      parents: node.parents,
      agent_id: node.agent_id,
      vector_clock: node.vector_clock,
      timestamp: node.timestamp
    }

    Blake3.hash_term(data_to_hash)
  end

  @doc """
  Signs the node using the agent's private key.
  """
  @spec sign(t(), binary()) :: t()
  def sign(%__MODULE__{hash: hash} = node, private_key) do
    signature = EightDCore.Crypto.Ed25519.sign(hash, private_key)
    %{node | signature: signature}
  end

  @doc """
  Verifies the node signature and its content hash.
  """
  @spec verify(t(), binary()) :: boolean()
  def verify(%__MODULE__{} = node, public_key) do
    valid_hash? = node.hash == compute_hash(node)
    
    valid_sig? =
      case node.signature do
        nil -> false
        sig -> EightDCore.Crypto.Ed25519.verify(node.hash, sig, public_key)
      end

    valid_hash? and valid_sig?
  end
end
