defmodule EightDCore.Storage.VFS do
  @moduledoc """
  Virtual File System (VFS) mappings for 8d.
  Translates the raw operating system files into immutable Merkle trees and blobs.
  """

  alias EightDCore.Storage.MnesiaStore
  alias EightDCore.Crypto.Blake3

  @default_ignores [".8d", ".git", "deps", "_build", ".elixir_ls", "Mnesia.nonode@nohost"]

  @doc """
  Traverses the directory, hashes files into blobs, and directories into trees.
  Stores the structures in Mnesia and returns the root tree hash.
  """
  def build_tree(path \\ File.cwd!()) do
    entries =
      path
      |> File.ls!()
      |> Enum.reject(&(&1 in @default_ignores))
      |> Enum.map(fn name ->
        full_path = Path.join(path, name)
        
        {type, hash} =
          if File.dir?(full_path) do
            {:tree, build_tree(full_path)}
          else
            {:blob, hash_and_store_file(full_path)}
          end
          
        {name, {type, hash}}
      end)
      |> Enum.into(%{})

    # Store the tree
    hash = Blake3.hash_term(entries)
    MnesiaStore.put_tree(hash, entries)

    hash
  end

  defp hash_and_store_file(path) do
    data = File.read!(path)
    hash = Blake3.hash_term(data)
    MnesiaStore.put_blob(hash, data)
    hash
  end

  @doc """
  Recursively compares a new tree against an old tree.
  Returns a list of structurally changed elements: {:added | :modified | :deleted, path, type}.
  """
  def diff_trees(old_hash, new_hash, current_path \\ "") do
    if old_hash == new_hash do
      [] # Identical sub-graph
    else
      old_entries = get_tree_entries(old_hash)
      new_entries = get_tree_entries(new_hash)
      
      all_names = Enum.uniq(Map.keys(old_entries) ++ Map.keys(new_entries))
      
      Enum.flat_map(all_names, fn name ->
        node_path = Path.join(current_path, name)
        old_val = Map.get(old_entries, name)
        new_val = Map.get(new_entries, name)
        
        cond do
          old_val == nil ->
            # Added
            [{:added, node_path, elem(new_val, 0)}] ++ diff_recursive(nil, new_val, node_path)
          new_val == nil ->
            # Deleted
            [{:deleted, node_path, elem(old_val, 0)}] ++ diff_recursive(old_val, nil, node_path)
          old_val != new_val ->
            # Modified
            [{:modified, node_path, elem(new_val, 0)}] ++ diff_recursive(old_val, new_val, node_path)
          true ->
            []
        end
      end)
    end
  end
  
  defp diff_recursive(old_val, new_val, path) do
    case {old_val, new_val} do
      {{:tree, h1}, {:tree, h2}} -> diff_trees(h1, h2, path)
      {{:tree, h1}, nil} -> diff_trees(h1, nil, path)
      {nil, {:tree, h2}} -> diff_trees(nil, h2, path)
      _ -> []
    end
  end

  defp get_tree_entries(nil), do: %{}
  defp get_tree_entries(hash) do
    case MnesiaStore.get_tree(hash) do
      {:ok, e} -> e
      _ -> %{}
    end
  end
end
