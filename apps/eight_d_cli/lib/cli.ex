defmodule EightDCli.CLI do
  @moduledoc """
  Command-line interface for the 8d Agent-Native version control system.
  """

  alias EightDCognitive.Memory.GCCPrimitives
  alias EightDCore.Storage.MnesiaStore
  alias EightDCore.Crypto.Ed25519
  alias EightDCore.CRDT.VectorClock

  @doc """
  Main entry point for the generated escript.
  """
  def main(args) do
    # Boot the necessary apps since escripts don't launch umbrellas automatically
    # For a production escript, all dependent apps (like mnesia) must be started.
    {:ok, _} = Application.ensure_all_started(:eight_d_swarm)

    {opts, command, _} = OptionParser.parse(args, 
      strict: [message: :string, cwd: :string], 
      aliases: [m: :message]
    )

    if Keyword.has_key?(opts, :cwd) do
      File.cd!(opts[:cwd])
    end

    case command do
      ["init"] ->
        init_repo()

      ["commit"] ->
        message = Keyword.get(opts, :message, "No payload message provided")
        commit(message)

      ["branch"] ->
        branch()

      ["log"] ->
        log()
        
      ["status"] ->
        status()
        
      ["diff"] ->
        diff()

      ["consolidate", hash1, hash2] ->
        consolidate(hash1, hash2)
        
      ["sync", peer_host, peer_port] ->
        sync_tcp(peer_host, String.to_integer(peer_port))

      ["serve", port] ->
        serve_tcp(String.to_integer(port))

      _ ->
        print_help()
    end
    
    # Gracefully shut down Mnesia to flush all pending disc_copy transactions 
    # to the DCD/DAT files before the Beam VM halts abruptly.
    :mnesia.stop()
  end

  defp status do
    current_tree = EightDCore.Storage.VFS.build_tree()
    
    frontier_tree = 
      case GCCPrimitives.branch() do
        [] -> nil
        [tip | _] -> 
          case MnesiaStore.get(tip) do
            {:ok, %{payload: %{tree_hash: th}}} -> th
            _ -> nil
          end
      end
      
    diffs = EightDCore.Storage.VFS.diff_trees(frontier_tree, current_tree)
    
    if diffs == [] do
      IO.puts("Uncommitted Agent Workspace State:\n- Clean (No changes)")
    else
      IO.puts("Uncommitted Agent Workspace State:")
      Enum.each(diffs, fn {status, path, _type} -> 
        IO.puts("  [#{String.upcase(to_string(status))}]\t#{path}")
      end)
    end
  end
  
  defp diff do
    current_tree = EightDCore.Storage.VFS.build_tree()
    
    frontier_tree = 
      case GCCPrimitives.branch() do
        [] -> nil
        [tip | _] -> 
          case MnesiaStore.get(tip) do
            {:ok, %{payload: %{tree_hash: th}}} -> th
            _ -> nil
          end
      end
      
    diffs = EightDCore.Storage.VFS.diff_trees(frontier_tree, current_tree)
    
    if diffs == [] do
      IO.puts("DAG Frontier vs Workspace Diff:\n- No pending modifications.")
    else
      IO.puts("DAG Frontier vs Workspace Diff:")
      Enum.each(diffs, fn {status, path, type} -> 
        IO.puts("  #{String.upcase(to_string(status))}\t[#{type}]\t#{path}")
      end)
    end
  end
  
  defp consolidate(hash1, hash2) do
    IO.puts("Consolidating independent agent branches: [#{hash1}] and [#{hash2}]")
    
    priv = get_or_generate_key()
    clock = MnesiaStore.get_clock("local_user")
    
    {:ok, node, new_clock} = GCCPrimitives.consolidate("Merged Swarm Output", "local_user", clock, priv, [hash1, hash2])
    MnesiaStore.put_clock("local_user", new_clock)
    IO.puts("Merge successful according to Set-Union CRDT rules: [#{String.slice(node.hash, 0..7)}]")
  end
  
  defp serve_tcp(port) do
    IO.puts("Starting 8d TCP syncing server on port #{port}...")
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: 4, active: false, reuseaddr: true])
    
    # Loop infinitely to accept peers
    accept_loop(listen_socket)
  end

  defp accept_loop(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    
    case receive_packet(socket) do
      {:ok, data} ->
        client_frontier = :erlang.binary_to_term(data)
        IO.puts("Peer connected. Client frontier: #{inspect(client_frontier)}. Pushing network deltas...")
        
        state = MnesiaStore.export_delta(client_frontier)
        encoded = :erlang.term_to_binary(state)
        
        :gen_tcp.send(socket, encoded)
        :gen_tcp.close(socket)
      _ ->
        :gen_tcp.close(socket)
    end
    
    accept_loop(listen_socket)
  end
  
  defp sync_tcp(host, port) do
    IO.puts("Attempting TCP connection to 8d mesh peer: #{host}:#{port}")
    
    host_charlist = String.to_charlist(host)
    case :gen_tcp.connect(host_charlist, port, [:binary, packet: 4, active: false], 5000) do
      {:ok, socket} ->
        IO.puts("Connected. Transmitting local causal vectors...")
        my_frontier = MnesiaStore.get_frontier()
        request_data = :erlang.term_to_binary(my_frontier)
        
        :gen_tcp.send(socket, request_data)
        
        {:ok, data} = receive_packet(socket)
        :gen_tcp.close(socket)
        
        remote_state = :erlang.binary_to_term(data)
        MnesiaStore.import_state(remote_state)
        
        # Merge remote frontier nodes into local DAG via node commits
        Enum.each(remote_state.frontier, fn hash -> 
          case MnesiaStore.get(hash) do
            {:ok, node} -> 
              GenServer.call(EightDCore.MerkleDAG.DAG, {:update_frontier, node})
            _ -> :ok
          end
        end)
        
        IO.puts("Sync complete. Delta state resolved correctly.")
      {:error, reason} ->
        IO.puts("Failed to connect to peer: #{inspect(reason)}")
    end
  end

  defp receive_packet(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  defp init_repo do
    IO.puts("Initializing empty 8d repository...")
    MnesiaStore.init_store()
    
    # Generate an identity for this local agent/user in .8d/identity
    if File.exists?(".8d/identity") do
      IO.puts("Repository already initialized.")
    else
      {_pub, priv} = Ed25519.generate_keypair()
      File.write!(".8d/identity", Base.encode16(priv))
      
      # Store initial genesis commit
      GCCPrimitives.commit(%{type: :roadmap, content: "Genesis commit: Repository Initialized"}, "local_user", VectorClock.new(), priv)
      
      IO.puts("Done. (Generated identity in .8d/identity)")
    end
  end

  defp commit(message) do
    # Snapshot working directory
    tree_hash = EightDCore.Storage.VFS.build_tree()

    priv = get_or_generate_key()
    clock = MnesiaStore.get_clock("local_user")
    
    {:ok, node, new_clock} = GCCPrimitives.commit(%{type: :work, data: message, tree_hash: tree_hash}, "local_user", clock, priv)
    MnesiaStore.put_clock("local_user", new_clock)
    IO.puts("Committed [#{String.slice(node.hash, 0..7)}]: #{message}")
  end

  defp branch do
    frontier = GCCPrimitives.branch()
    IO.puts("Current Branch DAG Frontier Hashes:")
    Enum.each(frontier, &IO.puts(" - #{&1}"))
    if frontier == [] do
      IO.puts("(Empty - you are at genesis)")
    end
  end

  defp log do
    all_nodes = MnesiaStore.all()
    # Sort by timestamp via SEDM filter simply
    sorted = EightDCognitive.Memory.DecayEngine.filter(all_nodes)
    
    log_content = EightDCognitive.VFS.Projection.generate_log_md(sorted)
    
    if log_content == "" do
      IO.puts("No history found.")
    else
      IO.puts("--- 8d DAG LOG ---")
      IO.puts(log_content)
    end
  end

  defp print_help do
    IO.puts("""
    8d - Agent-Native Git Alternative (CASM Architecture)

    Commands:
      8d init                           - Initialize the repository and Mnesia schema
      8d commit -m "msg"                - Create a new DAG node
      8d branch                         - List the current graph frontier (leaf nodes)
      8d log                            - View history of the DAG graph
      8d status                         - View dirty agent workspace buffers
      8d diff                           - View uncommitted deltas against the DAG tip
      8d consolidate <hash1> <hash2>    - Semantically merge two divergent graph leaves
      8d serve <port>                   - Launch a TCP daemon exporting the local DAG branch
      8d sync <host> <port>             - Fetch and merge state from a remote DAG host via TCP
    """)
    System.halt(1)
  end
  
  defp get_or_generate_key do
    case File.read(".8d/identity") do
      {:ok, key} ->
        Base.decode16!(String.trim(key))
      {:error, _} ->
        {_pub, priv} = Ed25519.generate_keypair()
        priv
    end
  end
end
