defmodule EightDSwarm.Epistemic.Correlation do
  @moduledoc """
  Grid-Cell Correlation Discounting (from AIMP).
  Reduces hyper-confidence when multiple LLM agents report the exact same observation.
  """

  @doc """
  Discounts correlated observations.
  Accepts a list of payloads, groups exact matches, and applies
  geometric decay to the weights.
  """
  def discount(observations) do
    observations
    |> Enum.frequencies()
    |> Enum.map(fn {obs, count} ->
      # Geometric decay algorithm: Weight = sum( (1/2)^i ) for i in 1..count
      weight = 
        1..count 
        |> Enum.map(fn i -> :math.pow(0.5, i - 1) end) 
        |> Enum.sum()
        
      {obs, weight}
    end)
    |> Enum.into(%{})
  end
end
