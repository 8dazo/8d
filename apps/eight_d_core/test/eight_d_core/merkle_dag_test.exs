defmodule EightDCore.MerkleDAGTest do
  use ExUnit.Case
  alias EightDCore.MerkleDAG.{Node, DAG}
  alias EightDCore.Crypto.Ed25519
  alias EightDCore.CRDT.VectorClock

  setup do
    EightDCore.Storage.MnesiaStore.clear_for_test()
    :sys.replace_state(DAG, fn _ -> %{frontier: []} end)
    :ok
  end

  test "creates, hashes, and signs a node" do
    {pub_key, priv_key} = Ed25519.generate_keypair()
    clock = VectorClock.increment(VectorClock.new(), "agent1")

    node = Node.new(%{data: "hello"}, [], "agent1", clock)
    assert node.hash != nil

    signed_node = Node.sign(node, priv_key)
    assert Node.verify(signed_node, pub_key)
  end

  test "DAG appends nodes and updates frontier" do
    n1 = Node.new(%{msg: "commit 1"}, [], "agent1", %{"agent1" => 1})
    :ok = DAG.append(n1)

    assert DAG.get_frontier() == [n1.hash]

    n2 = Node.new(%{msg: "commit 2"}, [n1.hash], "agent1", %{"agent1" => 2})
    :ok = DAG.append(n2)

    assert DAG.get_frontier() == [n2.hash]
  end

  test "DAG branches create multiple frontiers" do
    n1 = Node.new(%{msg: "common"}, [], "agent1", %{"agent1" => 1})
    :ok = DAG.append(n1)

    # Branch A
    n2a = Node.new(%{msg: "branch A"}, [n1.hash], "agentA", %{"agent1" => 1, "agentA" => 1})
    :ok = DAG.append(n2a)

    # Branch B
    n2b = Node.new(%{msg: "branch B"}, [n1.hash], "agentB", %{"agent1" => 1, "agentB" => 1})
    :ok = DAG.append(n2b)

    # The frontier should now contain BOTH heads
    frontier = DAG.get_frontier()
    assert length(frontier) == 2
    assert Enum.member?(frontier, n2a.hash)
    assert Enum.member?(frontier, n2b.hash)
  end
end
