defmodule EightDCognitive.MemoryTest do
  use ExUnit.Case

  alias EightDCore.CRDT.VectorClock
  alias EightDCore.Crypto.Ed25519
  alias EightDCore.MerkleDAG.{Node, DAG}
  alias EightDCognitive.Memory.{GCCPrimitives, DecayEngine}
  alias EightDCognitive.VFS.Projection

  setup do
    EightDCore.Storage.MnesiaStore.clear_for_test()
    :sys.replace_state(DAG, fn _ -> %{frontier: []} end)
    :ok
  end

  test "GCC COMMIT creates a DAG node" do
    {_pub, priv} = Ed25519.generate_keypair()
    clock = VectorClock.new()

    {:ok, node, new_clock} = GCCPrimitives.commit(%{data: "test"}, "agent1", clock, priv)

    assert node.payload[:data] == "test"
    assert new_clock == %{"agent1" => 1}
    assert DAG.get_frontier() == [node.hash]
  end

  test "DecayEngine scores newer nodes higher" do
    n1 = %Node{timestamp: 100, payload: "old"}
    n2 = %Node{timestamp: 200, payload: "new"}
    
    current_time = 200
    
    s1 = DecayEngine.utility_score(n1, current_time)
    s2 = DecayEngine.utility_score(n2, current_time)
    
    assert s2 > s1
    assert s2 == 1.0 # 0 age -> score 1.0
  end

  test "VFS Projection generates main.md and log.md" do
    n1 = %Node{timestamp: 1, agent_id: "A", payload: %{type: :roadmap, content: "Initial Roadmap"}, hash: "h1"}
    n2 = %Node{timestamp: 2, agent_id: "B", payload: %{type: :work, data: "did something"}, hash: "h2"}
    n3 = %Node{timestamp: 3, agent_id: "C", payload: %{type: :consolidate, result: "Resolved ABC"}, hash: "h3"}

    # Mocking the output of DecayEngine.filter
    filtered = [
      {"h3", n3, 1.0},
      {"h2", n2, 0.9},
      {"h1", n1, 0.8}
    ]

    main_md = Projection.generate_main_md(filtered)
    assert main_md =~ "Resolved ABC"
    assert main_md =~ "Initial Roadmap"
    refute main_md =~ "did something"

    log_md = Projection.generate_log_md(filtered)
    assert log_md =~ "[Agent: A]"
    assert log_md =~ "Initial Roadmap"
    assert log_md =~ ":roadmap"
  end
end
