defmodule EightDSwarm.Orchestrator.Coordinator do
  @moduledoc """
  The Coordinator Agent manages objective decomposition.
  It writes tasks to the main.md roadmap and spawns Implementor agents.
  """

  alias EightDCognitive.Memory.GCCPrimitives
  alias EightDCore.CRDT.VectorClock
  alias EightDCore.Crypto.Ed25519

  @doc """
  Initializes a new task objective and commits it to the DAG as a :roadmap node.
  Then spawns N implementor agents.
  """
  def start_objective(objective, n_agents, agent_id \\ "coordinator") do
    {_pub, priv} = Ed25519.generate_keypair()
    clock = VectorClock.new()

    # Commit objective
    payload = %{type: :roadmap, content: objective}
    {:ok, _node, _clock} = GCCPrimitives.commit(payload, agent_id, clock, priv)

    # Spawn N implementors dynamically
    # In a real app this would use a DynamicSupervisor
    Enum.map(1..n_agents, fn i ->
      Task.async(fn ->
        EightDSwarm.Orchestrator.Implementor.execute("#{agent_id}-imp-#{i}", objective)
      end)
    end)
  end
end
