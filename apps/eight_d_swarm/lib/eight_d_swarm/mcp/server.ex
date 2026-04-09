defmodule EightDSwarm.MCP.Server do
  @moduledoc """
  Model Context Protocol (MCP) server for 8d.
  Translates external tool calls from AI agents into native EightD operations.
  """

  alias EightDSwarm.Orchestrator.{Coordinator, Verifier}
  alias EightDCognitive.Memory.GCCPrimitives

  @doc """
  Handles an incoming MCP JSON-RPC call.
  For MVP, this takes a map rather than parsing raw stdio.
  """
  def handle_call(%{"method" => "8d.branch"}) do
    frontier = GCCPrimitives.branch()
    {:ok, %{"result" => frontier}}
  end

  def handle_call(%{"method" => "8d.consolidate", "params" => %{"message" => _msg, "branches" => branches}}) do
    {:ok, node, _clk} = Verifier.verify_and_merge(branches)
    # The actual verifier would resolve logic. Here we just commit it back.
    {:ok, %{"result" => node.hash}}
  end

  def handle_call(%{"method" => "8d.start_objective", "params" => %{"objective" => obj, "n_agents" => n}}) do
    Coordinator.start_objective(obj, n)
    {:ok, %{"result" => "Started #{n} implementors"}}
  end

  def handle_call(_) do
    {:error, "Unknown MCP Method"}
  end
end
