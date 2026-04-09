defmodule EightDCore.Storage.MnesiaStore do
  @moduledoc """
  Persistent, distributed storage for DAG nodes using Erlang's Mnesia.
  Nodes are completely immutable, so writes are purely append-only mappings
  from hash to Node structure.
  """
  use EightDCore.Storage.Store

  require Logger
  import Record, only: [defrecordp: 2]

  # Define atomic record structure mapping to the Mnesia table
  # hash is the primary key
  defrecordp :dag_node, [:hash, :node_struct]
  defrecordp :dag_blob, [:hash, :data]
  defrecordp :dag_tree, [:hash, :entries]
  defrecordp :schema_version, [:key, :version]
  defrecordp :dag_meta, [:key, :value]

  @current_schema_version 1

  @doc """
  Initializes the Mnesia schema and creates the `dag_node` table if
  it doesn't already exist. Must be called when the application starts.
  """
  def init_store() do
    # Configure Mnesia to store in the current repository's .8d folder
    repo_dir = Path.join(File.cwd!(), ".8d/mnesia")
    File.mkdir_p!(repo_dir)
    Application.put_env(:mnesia, :dir, String.to_charlist(repo_dir))

    nodes = [node()]

    :mnesia.stop()
    
    case :mnesia.create_schema(nodes) do
      :ok -> Logger.info("Mnesia schema created successfully.")
      {:error, {_, {:already_exists, _}}} -> Logger.info("Mnesia schema already exists.")
      error -> Logger.error("Failed to create Mnesia schema: #{inspect(error)}")
    end

    :mnesia.start()

    # Create the tables
    case :mnesia.create_table(:dag_node, [
      attributes: [:hash, :node_struct],
      disc_copies: nodes,
      type: :set
    ]) do
      {:atomic, :ok} -> Logger.debug("Table :dag_node created.")
      {:aborted, {:already_exists, :dag_node}} -> Logger.debug("Table :dag_node already exists.")
      error -> Logger.error("Failed to create :dag_node table: #{inspect(error)}")
    end

    case :mnesia.create_table(:schema_version, [
      attributes: [:key, :version],
      disc_copies: nodes,
      type: :set
    ]) do
      {:atomic, :ok} -> 
        Logger.debug("Table :schema_version created.")
        :mnesia.transaction(fn -> :mnesia.write(schema_version(key: :schema, version: @current_schema_version)) end)
      {:aborted, {:already_exists, :schema_version}} -> 
        check_and_run_migrations()
      error -> Logger.error("Failed to create :schema_version table: #{inspect(error)}")
    end

    case :mnesia.create_table(:dag_meta, [
      attributes: [:key, :value],
      disc_copies: nodes,
      type: :set
    ]) do
      {:atomic, :ok} -> Logger.debug("Table :dag_meta created.")
      {:aborted, {:already_exists, :dag_meta}} -> Logger.debug("Table :dag_meta already exists.")
      error -> Logger.error("Failed to create :dag_meta table: #{inspect(error)}")
    end

    case :mnesia.create_table(:dag_blob, [
      attributes: [:hash, :data],
      disc_copies: nodes,
      type: :set
    ]) do
      {:atomic, :ok} -> Logger.debug("Table :dag_blob created.")
      {:aborted, {:already_exists, :dag_blob}} -> Logger.debug("Table :dag_blob already exists.")
      error -> Logger.error("Failed to create :dag_blob table: #{inspect(error)}")
    end

    case :mnesia.create_table(:dag_tree, [
      attributes: [:hash, :entries],
      disc_copies: nodes,
      type: :set
    ]) do
      {:atomic, :ok} -> Logger.debug("Table :dag_tree created.")
      {:aborted, {:already_exists, :dag_tree}} -> Logger.debug("Table :dag_tree already exists.")
      error -> Logger.error("Failed to create :dag_tree table: #{inspect(error)}")
    end

    :ok = :mnesia.wait_for_tables([:dag_node, :schema_version, :dag_meta, :dag_blob, :dag_tree], 5000)
  end

  defp check_and_run_migrations() do
    result = case :mnesia.transaction(fn -> :mnesia.read({:schema_version, :schema}) end) do
      {:atomic, r} -> r
      {:aborted, {:no_exists, :schema_version}} -> 
        # Create it dynamically if reading fails
        :mnesia.create_table(:schema_version, [
          attributes: [:key, :version],
          disc_copies: [node()],
          type: :set
        ])
        :mnesia.transaction(fn -> :mnesia.write(schema_version(key: :schema, version: @current_schema_version)) end)
        [schema_version(version: @current_schema_version)]
      _ -> []
    end
    
    version = case result do
      [schema_version(version: v)] -> v
      [] -> 1
    end

    cond do
      version == @current_schema_version ->
        Logger.debug("Mnesia schema is up to date (v#{version}).")
      version < @current_schema_version ->
        Logger.info("Migrating Mnesia schema from v#{version} to v#{@current_schema_version}...")
        :mnesia.transaction(fn -> :mnesia.write(schema_version(key: :schema, version: @current_schema_version)) end)
      true ->
        Logger.warning("Database schema version is newer than application code!")
    end
  end

  @impl true
  def put(hash, node) do
    # Mnesia transactions are reliable and atomic
    transaction = fn ->
      :mnesia.write(dag_node(hash: hash, node_struct: node))
    end

    case :mnesia.transaction(transaction) do
      {:atomic, :ok} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  @impl true
  def get(hash) do
    transaction = fn ->
      :mnesia.read({:dag_node, hash})
    end

    case :mnesia.transaction(transaction) do
      {:atomic, [dag_node(node_struct: node)]} -> {:ok, node}
      {:atomic, []} -> {:error, :not_found}
      {:aborted, reason} -> {:error, reason}
    end
  end

  def put_frontier(frontier) do
    :mnesia.transaction(fn ->
      :mnesia.write(dag_meta(key: :frontier, value: frontier))
    end)
  end

  def get_frontier() do
    case :mnesia.transaction(fn -> :mnesia.read({:dag_meta, :frontier}) end) do
      {:atomic, [dag_meta(value: val)]} -> val
      {:atomic, other} -> 
        Logger.debug("get_frontier atomic other: #{inspect(other)}")
        []
      other -> 
        Logger.debug("get_frontier other: #{inspect(other)}")
        []
    end
  end

  def get_clock(agent_id) do
    case :mnesia.transaction(fn -> :mnesia.read({:dag_meta, {:clock, agent_id}}) end) do
      {:atomic, [dag_meta(value: val)]} -> val
      _ -> EightDCore.CRDT.VectorClock.new()
    end
  end

  def put_clock(agent_id, clock) do
    :mnesia.transaction(fn -> :mnesia.write(dag_meta(key: {:clock, agent_id}, value: clock)) end)
  end

  @doc """
  Exports only the delta missing from the client's frontier for efficient P2P Transfers.
  """
  def export_delta(client_frontier) do
    server_frontier = get_frontier()
    
    server_nodes_list = Enum.flat_map(server_frontier, &EightDCore.MerkleDAG.DAG.ancestors/1) ++ server_frontier
    server_nodes = Enum.uniq(server_nodes_list)
    
    client_known_list = Enum.flat_map(client_frontier, &EightDCore.MerkleDAG.DAG.ancestors/1) ++ client_frontier
    client_known = Enum.uniq(client_known_list) |> MapSet.new()
    
    missing_node_hashes = Enum.reject(server_nodes, &MapSet.member?(client_known, &1))
    
    nodes = 
      Enum.map(missing_node_hashes, fn h -> 
        case :mnesia.dirty_read({:dag_node, h}) do
          [record] -> record
          [] -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      
    root_tree_hashes = 
      nodes 
      |> Enum.map(fn {:dag_node, _h, %{payload: p}} -> p[:tree_hash] end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      
    {tree_hashes, blob_hashes} = gather_deps(root_tree_hashes, MapSet.new(), MapSet.new())
    
    trees = Enum.map(tree_hashes, fn h -> hd(:mnesia.dirty_read({:dag_tree, h})) end)
    blobs = Enum.map(blob_hashes, fn h -> hd(:mnesia.dirty_read({:dag_blob, h})) end)
    
    %{nodes: nodes, trees: trees, blobs: blobs, frontier: server_frontier}
  end

  defp gather_deps([], trees_acc, blobs_acc), do: {trees_acc, blobs_acc}
  defp gather_deps([tree_hash | rest], trees_acc, blobs_acc) do
    if MapSet.member?(trees_acc, tree_hash) do
      gather_deps(rest, trees_acc, blobs_acc)
    else
      trees_acc = MapSet.put(trees_acc, tree_hash)
      
      case :mnesia.dirty_read({:dag_tree, tree_hash}) do
        [{:dag_tree, ^tree_hash, entries}] ->
          # entries is %{name => {type, hash}}
          new_trees = 
            Enum.filter(entries, fn {_, {type, _}} -> type == :tree end)
            |> Enum.map(fn {_, {_, h}} -> h end)
            
          new_blobs = 
            Enum.filter(entries, fn {_, {type, _}} -> type == :blob end)
            |> Enum.map(fn {_, {_, h}} -> h end)
            
          blobs_acc = MapSet.union(blobs_acc, MapSet.new(new_blobs))
          gather_deps(new_trees ++ rest, trees_acc, blobs_acc)
        [] ->
          gather_deps(rest, trees_acc, blobs_acc)
      end
    end
  end
  
  @doc """
  Imports remote state safely merging it via Set-Union CRDT rules into local storage.
  """
  def import_state(%{nodes: new_n, trees: new_t, blobs: new_b}) do
    :mnesia.transaction(fn ->
      Enum.each(new_n, &:mnesia.write/1)
      Enum.each(new_t, &:mnesia.write/1)
      Enum.each(new_b, &:mnesia.write/1)
    end)
  end

  def put_blob(hash, data) do
    :mnesia.transaction(fn -> :mnesia.write(dag_blob(hash: hash, data: data)) end)
  end

  def get_blob(hash) do
    case :mnesia.transaction(fn -> :mnesia.read({:dag_blob, hash}) end) do
      {:atomic, [dag_blob(data: d)]} -> {:ok, d}
      _ -> {:error, :not_found}
    end
  end

  def put_tree(hash, entries) do
    :mnesia.transaction(fn -> :mnesia.write(dag_tree(hash: hash, entries: entries)) end)
  end

  def get_tree(hash) do
    case :mnesia.transaction(fn -> :mnesia.read({:dag_tree, hash}) end) do
      {:atomic, [dag_tree(entries: e)]} -> {:ok, e}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Retrieves all nodes from the store.
  Useful for the DecayEngine to process the entire graph history.
  Warning: In a giant graph this should be paginated or streamed,
  but suitable for MVP.
  """
  def all do
    transaction = fn ->
      # Select all records
      :mnesia.match_object({:dag_node, :_, :_})
    end

    case :mnesia.transaction(transaction) do
      {:atomic, results} -> 
        # Convert list of records back to a map of %{hash => node}
        Enum.into(results, %{}, fn dag_node(hash: h, node_struct: n) -> {h, n} end)
      {:aborted, _} -> 
        %{}
    end
  end

  @doc """
  Clears the database (purely for tests).
  """
  def clear_for_test do
    :mnesia.clear_table(:dag_node)
  end
end
