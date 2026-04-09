defmodule EightDCore.MerkleDAG.DAG do
  @moduledoc """
  The core Merkle-DAG index. Uses the Store to hold nodes.
  Maintains the frontier (leaves) of the graph.
  """

  use GenServer
  alias EightDCore.MerkleDAG.Node
  alias EightDCore.Storage.MnesiaStore
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Appends a new node to the DAG.
  """
  @spec append(Node.t()) :: :ok
  def append(%Node{hash: hash} = node) do
    case MnesiaStore.put(hash, node) do
      :ok ->
        GenServer.call(__MODULE__, {:update_frontier, node})
        :ok
      {:error, reason} -> 
        {:error, reason}
    end
  end

  @doc """
  Returns the current frontier (tip/leaves) of the DAG.
  This is useful for knowing which parents to set for a new node.
  """
  def get_frontier do
    GenServer.call(__MODULE__, :get_frontier)
  end

  @impl true
  def init(_) do
    # Reload frontier persistently
    frontier = MnesiaStore.get_frontier()
    {:ok, %{frontier: frontier}}
  end

  @impl true
  def handle_call({:update_frontier, %Node{} = node}, _from, state) do
    # Remove any current frontier nodes that are parents of the new node
    # Add new node to the frontier
    new_frontier = 
      state.frontier
      |> Enum.reject(fn f -> Enum.member?(node.parents, f) end)
      |> Enum.concat([node.hash])
      |> Enum.uniq()

    MnesiaStore.put_frontier(new_frontier)

    {:reply, :ok, %{state | frontier: new_frontier}}
  end

  @impl true
  def handle_call(:get_frontier, _from, state) do
    {:reply, state.frontier, state}
  end

  @doc """
  Traverse back from a single point fetching all ancestors causally.
  Returns a list of Node structs sorted roughly by traversal order (reverse causal).
  """
  @spec ancestors(String.t()) :: [Node.t()]
  def ancestors(hash) do
    do_ancestors([hash], MapSet.new(), [])
  end

  defp do_ancestors([], _visited, acc), do: Enum.reverse(acc)
  defp do_ancestors([current | rest], visited, acc) do
    if MapSet.member?(visited, current) do
      do_ancestors(rest, visited, acc)
    else
      visited = MapSet.put(visited, current)
      
      case MnesiaStore.get(current) do
        {:ok, node} ->
          # Next step: go to parents
          next_to_visit = rest ++ node.parents
          do_ancestors(next_to_visit, visited, [node | acc])
        {:error, _} ->
          do_ancestors(rest, visited, acc)
      end
    end
  end

  @doc """
  Finds the shortest linear delta path (diff) between two hashes in the graph.
  Usually used for determining what nodes need to be synced to a remote peer.
  """
  @spec path_between(String.t(), String.t()) :: [Node.t()]
  def path_between(head_hash, base_hash) do
    head_ancestors = ancestors(head_hash)
    
    {path, _} = 
      Enum.reduce_while(head_ancestors, {[], false}, fn n, {acc, _found} ->
        if n.hash == base_hash do
          {:halt, {acc, true}}
        else
          {:cont, {[n | acc], false}}
        end
      end)
      
    Enum.reverse(path)
  end
end
