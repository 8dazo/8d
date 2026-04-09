defmodule EightDCore.CRDT.VectorClockTest do
  use ExUnit.Case, async: true
  alias EightDCore.CRDT.VectorClock

  test "increment/2 correctly increases specific agent tick" do
    c = VectorClock.new()
    assert c == %{}
    c2 = VectorClock.increment(c, "agent_A")
    assert c2 == %{"agent_A" => 1}
    c3 = VectorClock.increment(c2, "agent_A")
    assert c3 == %{"agent_A" => 2}
  end

  test "compare/2 determines causal histories" do
    c1 = %{"agent_A" => 1}
    c2 = %{"agent_A" => 2}
    c3 = %{"agent_A" => 1, "agent_B" => 1}
    
    assert VectorClock.compare(c1, c1) == :eq
    assert VectorClock.compare(c1, c2) == :lt
    assert VectorClock.compare(c2, c1) == :gt
    assert VectorClock.compare(c2, c3) == :concurrent
  end
end
