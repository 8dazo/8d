defmodule EightDCognitive.VFS.Projection do
  @moduledoc """
  Projects the Merkle-DAG into a Virtual File System structure (main.md, log.md)
  that makes sense contextually for LLM agents.
  """

  @doc """
  Reconstructs `main.md` - the core roadmap - from the DAG.
  It extracts ONLY the payloads from nodes tagged as `:consolidate` or `:roadmap`.
  """
  def generate_main_md(sorted_nodes) do
    # Extract only consolidate/roadmap events in chronological order
    sorted_nodes
    |> Enum.filter(fn {_, node, _} -> 
         is_map(node.payload) and node.payload[:type] in [:consolidate, :roadmap] 
       end)
    |> Enum.map(fn {_, node, _} -> node.payload[:result] || node.payload[:content] end)
    |> Enum.join("\n\n---\n\n")
  end

  @doc """
  Reconstructs `log.md` (Observation-Thought-Action traces) from recent nodes.
  """
  def generate_log_md(sorted_nodes) do
    sorted_nodes
    |> Enum.map(fn {hash, node, score} ->
         "[#{node.timestamp}] [Agent: #{node.agent_id}] [Score: #{Float.round(score, 3)}] (Hash: #{String.slice(hash, 0..7)})\n" <>
         "Payload: #{inspect(node.payload)}\n"
       end)
    |> Enum.join("\n")
  end
end
