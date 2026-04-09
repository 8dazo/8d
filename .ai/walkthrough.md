# 8d Deployment Walkthrough & Documentation

This walkthrough details exactly how autonomous AI Swarms interact with the `8d` logic natively, how to package the system onto a completely fresh node, and details how the underlying demonstration bash environments execute.

---

## 1. How AI Agent Swarms Interact with 8d

`8d` was fundamentally built to eliminate the notorious "git index.lock" merge conflicts that instantly halt execution when swarms of parallel agents operate inside a single source codebase autonomously.

### **The Active Swarm Interaction Loop:**
1. **Agent Spawning:** An orchestrator Large Language Model (like Cortex, Claude Code, or AutoGPT) breaks down an overarching goal into 10 sub-tasks, dropping 10 parallel Agents (`Implementor A` through `Implementor J`) onto the host OS file system.
2. **Context Intake (Reads):** Rather than tokenizing the entire codebase linearly and wasting maximum context tokens, Agents execute `8d log` to index the active Merkle-DAG state mappings. The `SEDM Decay Engine` automatically scores and filters the historical graph so agents natively read context proportionally based on real-time causality and node frequency (`utility = e^(-λt)`).
3. **Execution Sandbox (Writes):** The 10 agents openly write their modifications to the physical files concurrently. 
4. **Graph Commit Sequences:** Agents unilaterally execute `./8d commit -m "Updated Context"`. 
   - When firing, `8d` invokes a custom Rust `BLAKE3 Native NIF` to aggressively hash the raw file changes into raw bytes natively within 5 milliseconds.
   - It captures the precise topological snapshot exactly as seen by the executing Agent and locks the execution with their unique Ed25519 Cryptographic fingerprint into an Erlang Mnesia Database format as a `Causal Lockless CRDT vector`. No file `index.lock` collisions ever block the execution loop.
5. **Autonomic Merge Arbitration:** Once a set of Agents finish modifying code paths, an independent `Verifier` sub-agent is triggered. The Verifier LLM launches `./8d consolidate <branch_1> <branch_2>` enabling exactly mathematical Set-Union Set Merges across the topological maps independently of raw character matching diffs.

---

## 2. Setting Up 8d on New Devices

If deploying `8d` logic locally or on a completely fresh Continuous Integration / Virtual Machine compute layer, follow the precise compilation sequence:

### Prerequisites:
- `brew install elixir` (Requires OTP 26+, Elixir 1.15+)
- `brew install rust` (Cargo framework is explicitly mandated to compile the C-ABI libraries for the BLAKE3 performance bounds)

### Installation & Packaging Sequence:
```bash
# 1. Pull down the active Swarm Core logic
git clone https://github.com/8dazo/8d.git
cd 8d

# 2. Re-acquire dependencies and build native NIF functions bridging Erlang-Rust integration paths
mix deps.get
mix compile

# 3. Explicitly bundle the codebase down into a completely un-reliant standalone OS Release Binary 
mix release

# 4. Global deployment functionality is now bound directly. Fire the core CLI:
./_build/dev/rel/eight_d/bin/eight_d --help
```

---

## 3. Real-world Verification via Simulation Demos

The repository encapsulates two functional shell scripts located in `./demo_project` mathematically modeling both local single-node multi-agent swarming bounds, and pure-TCP isolated distributed networking models.

### Scenario A: Single Node Sandboxing (`demo_project/run_demo.sh`)
This script effectively models standard `Coordinator → Implementor → Verifier` behavioral parameters running in an explicitly shared filesystem footprint seamlessly.
- **Initialization:** An entirely unpolluted repository boots (`.8d` tracking directory binds dynamically).
- **Execution Overlap:** Two isolated `Implementors` separately perform state commits natively mutating `schema.sql` and `src/auth.ex` nodes concurrently.
- **Topological Modification:** The `Coordinator` executes a roadmap branch insertion logic modifying context mappings cleanly.
- **Delta Generation:** The raw native filesystem parses active files computing full runtime `BLAKE3` hash equivalents against the DAG Mnesia Frontier executing the `8d diff` bounds.
- **Merge Coalescence:** The local branches fire an operational `8d consolidate` explicitly merging overlapping nodes strictly logically without conflict locks.

### Scenario B: Multi-Node TCP Mesh Networking (`demo_project/run_sync_demo.sh`)
This script verifies absolute split-brain replication safety protocols eliminating Git remote clone failures. It concurrently handles two completely disjoint logical directories syncing operations precisely identically absent global schema states.
- **Node A (The Host):** Origin root directory initializes, builds a simple README layout boundary, and dynamically forces an exposed daemon listener utilizing `8d serve 8080`.
- **Node B (The Peer):** Boots dynamically from a structurally entirely unlinked path location mimicking standard `git clone` protocols initializing cleanly.
- **The Execution Synchronization:** Node B initiates `8d sync 127.0.0.1 8080`.
  - Node B serializes and wraps its current Merkle Set `Frontier Array` sending it immediately down the TCP socket natively.
  - Node A extracts the array boundary and walks mathematically backward along the Ancestry Directed Acyclic Graph tree paths intersecting against Node B's state. 
  - Having effectively computed the precise data gap between nodes, Node A pushes the explicit node packets into an encoded binary envelope down the exact TCP pipe.
  - Node B absorbs the network array cleanly merging into local Mnesia constraints effortlessly matching exact state convergence identical to git clone commands mathematically error-free.
