defmodule EightDSwarm.EpistemicTest do
  use ExUnit.Case
  alias EightDSwarm.Epistemic.Correlation

  test "discounting reduces weight of duplicate observations" do
    obs1 = "Found bug in lines 10-20"
    obs2 = "Found bug in lines 10-20"
    obs3 = "Found bug in lines 10-20"
    obs4 = "Distinct observation A"

    input = [obs1, obs2, obs3, obs4]
    
    weights = Correlation.discount(input)
    
    # "Found bug in lines 10-20" was seen 3 times.
    # W = (1/2)^0 + (1/2)^1 + (1/2)^2 = 1 + 0.5 + 0.25 = 1.75
    assert weights["Found bug in lines 10-20"] == 1.75
    
    # "Distinct observation A" was seen 1 time.
    # W = (1/2)^0 = 1.0
    assert weights["Distinct observation A"] == 1.0
  end
end
