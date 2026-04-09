defmodule EightDCognitive.Memory.DecayEngine do
  @moduledoc """
  Scalable Self-Evolving Distributed Memory (SEDM) framework implementation.
  Optimizes the cognitive context by computing utility scores and applying geometric decay.
  """

  alias EightDCore.MerkleDAG.Node

  @doc """
  Filters a map of DAG nodes based on their decay utility score.
  """
  def filter(nodes) do
    current_time = :os.system_time(:millisecond)

    nodes
    |> Enum.map(fn {hash, node} ->
      score = utility_score(node, current_time)
      {hash, node, score}
    end)
    # Sort by descending utility
    |> Enum.sort_by(fn {_, _, score} -> score end, :desc)
    # E.g., Take top N or drop ones below threshold
    # For MVP, we return them in sorted order with scores attached
  end

  @doc """
  Computes the utility score based on Recency.
  In a full system, Relevance (semantic embedding match) and Frequency are added.
  """
  def utility_score(%Node{timestamp: ts}, current_time) do
    # Simple exponential time decay 
    age_ms = current_time - ts
    
    # Half-life of 1 hour (3,600,000 ms)
    half_life = 3_600_000
    
    # decay factor: e ^ (- lambda * t)
    # lambda = ln(2) / half_life
    lambda = 0.693147 / half_life
    
    score = :math.exp(-lambda * age_ms)
    
    # Bound to [0.0, 1.0]
    max(0.0, min(1.0, score))
  end
end
