defmodule EightDCore.CRDT.MerkleCRDT do
  @moduledoc """
  State-based CRDT logic backed by the Merkle-DAG.
  Provides set-union merge semantics across replicas to guarantee convergence.
  """

  alias EightDCore.MerkleDAG.Node

  @type state :: %{String.t() => Node.t()}

  @doc """
  Returns an empty CRDT state.
  """
  @spec new() :: state()
  def new, do: %{}

  @doc """
  Merges two CRDT states via set union.
  Since DAG nodes are immutable and content-addressed, a simple Map merge
  guarantees commutativity, associativity, and idempotence.
  """
  @spec merge(state(), state()) :: state()
  def merge(state_a, state_b) do
    # Because a Node's key is its cryptographic hash, there can never be
    # differing nodes with the same key. We can simply Map.merge.
    Map.merge(state_a, state_b)
  end

  @doc """
  Computes the delta between two states to optimize synchronization bandwidth.
  Returns only the nodes present in `full_state` that are missing in `known_frontier`.
  
  In a real implementation over a Merkle Prolly Tree, this would traverse
  from the roots and only exchange differing prefixes. For now, it diffs the maps.
  """
  @spec delta(state(), state()) :: state()
  def delta(full_state, known_frontier) do
    Map.drop(full_state, Map.keys(known_frontier))
  end
end
