defmodule EightDCore.CRDT.VectorClock do
  @moduledoc """
  Implements a simple concurrent Vector Clock for tracking causal history
  without central locks.
  """

  @type t :: %{optional(String.t()) => non_neg_integer()}

  @doc """
  Returns a new, empty vector clock.
  """
  @spec new() :: t()
  def new, do: %{}

  @doc """
  Increments the clock for a specific agent.
  """
  @spec increment(t(), String.t()) :: t()
  def increment(clock, agent_id) do
    Map.update(clock, agent_id, 1, &(&1 + 1))
  end

  @doc """
  Merges two vector clocks, taking the maximum value for each agent.
  """
  @spec merge(t(), t()) :: t()
  def merge(clock_a, clock_b) do
    Map.merge(clock_a, clock_b, fn _k, val_a, val_b ->
      max(val_a, val_b)
    end)
  end

  @doc """
  Compares two vector clocks.
  Returns:
  - `:eq` if they are identical
  - `:lt` if clock_a strictly precedes clock_b
  - `:gt` if clock_a strictly succeeds clock_b
  - `:concurrent` if neither strictly precedes the other (divergent branches)
  """
  @spec compare(t(), t()) :: :eq | :lt | :gt | :concurrent
  def compare(clock_a, clock_b) do
    all_keys = Map.keys(clock_a) ++ Map.keys(clock_b) |> Enum.uniq()

    comparisons =
      Enum.map(all_keys, fn k ->
        val_a = Map.get(clock_a, k, 0)
        val_b = Map.get(clock_b, k, 0)
        cond do
          val_a == val_b -> :eq
          val_a < val_b  -> :lt
          val_a > val_b  -> :gt
        end
      end)
      |> Enum.reject(&(&1 == :eq))

    has_lt = :lt in comparisons
    has_gt = :gt in comparisons

    cond do
      not has_lt and not has_gt -> :eq
      has_lt and not has_gt     -> :lt
      has_gt and not has_lt     -> :gt
      true                      -> :concurrent
    end
  end
end
