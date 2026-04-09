defmodule EightDCognitive.Memory.GCCPrimitives do
  @moduledoc """
  Git-Context-Controller (GCC) primitives for agentic memory mapping
  over the Merkle-DAG. Instead of Git worktrees, agents use these
  functions to mutate state natively without index.lock collisions.
  """

  alias EightDCore.MerkleDAG.{Node, DAG}
  alias EightDCore.CRDT.VectorClock

  @doc """
  COMMIT: Generates a new DAG node.
  In a real system, this would capture the working directory contents payload.
  For MVP, it takes the direct payload (e.g. diff/trace).
  """
  def commit(payload, agent_id, clock, priv_key) do
    parents = DAG.get_frontier()
    new_clock = VectorClock.increment(clock, agent_id)
    
    node = Node.new(payload, parents, agent_id, new_clock)
    signed_node = Node.sign(node, priv_key)
    
    :ok = DAG.append(signed_node)
    
    {:ok, signed_node, new_clock}
  end

  @doc """
  BRANCH: Returns the current Merkle root/frontier so an agent can explicitly fork.
  """
  def branch do
    # Simply retrieves the frontier to use as the parent for the next commit
    DAG.get_frontier()
  end

  @doc """
  CONSOLIDATE: A stub for Semantic Merge. 
  Expects the outputs of divergent branches to be resolved by a Verifier agent,
  and then committed back safely.
  """
  def consolidate(resolved_payload, agent_id, clock, priv_key, branches \\ []) do
    parents = 
      case branches do
        [] -> DAG.get_frontier()
        specific -> specific # Explicitly defining the multi-parent merge
      end

    new_clock = VectorClock.increment(clock, agent_id)
    
    node = Node.new(%{type: :consolidate, result: resolved_payload}, parents, agent_id, new_clock)
    signed_node = Node.sign(node, priv_key)
    
    :ok = DAG.append(signed_node)
    {:ok, signed_node, new_clock}
  end

  @doc """
  RETRIEVE: Context loading for the LLM. 
  Fetches descendants up to a limit or passes through the SEDM engine.
  """
  def retrieve(_query_opts \\ []) do
    # Fetch all nodes from memory store
    # In production, this would traverse from frontier back via parents
    all_nodes = EightDCore.Storage.MnesiaStore.all()
    # Let DecayEngine select relevant nodes (simplified)
    EightDCognitive.Memory.DecayEngine.filter(all_nodes)
  end
end
