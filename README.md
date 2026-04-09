<div align="center">

<img src="public/logo_with _name.png" alt="8d Logo" width="400"/>

**Agent-Native Version Control for AI Swarms**

*A cryptographically-sound, distributed, DAG-based state machine built for agentic AI workflows — where `git` breaks, `8d` thrives.*

[![Elixir](https://img.shields.io/badge/Elixir-1.19-blueviolet?logo=elixir)](https://elixir-lang.org)
[![Rust NIF](https://img.shields.io/badge/BLAKE3-Rust_NIF-orange?logo=rust)](https://github.com/BLAKE3-team/BLAKE3)
[![Mnesia](https://img.shields.io/badge/Storage-Mnesia-blue)](https://www.erlang.org/doc/apps/mnesia/mnesia.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## Why 8d?

Git was designed for human authors committing deliberate, atomic changes in linear sequences. Modern AI agent swarms operate fundamentally differently. They generate hundreds of iterations concurrently, frequently diverge into dead-ends, and require contextual state retrieval based on cognitive relevance, rather than simple cronological ordering. 

| Dimension | Git | **8d** |
|---|---|---|
| **Concurrency** | Lock-based (`index.lock`) | Lockless CRDT Set-Union |
| **History** | Linear tree mapping | Causal Merkle-DAG Graph |
| **Merging** | Character diff + human resolution | Vector Clock ordering + Agent Verifier Merges |
| **Identity** | Username + email strings | Ed25519 cryptographic keypairs |
| **Hashing** | SHA-1 (CPU intensive) | BLAKE3 via Rust NIF (10x faster) |
| **Distribution** | SSH + HTTP remotes | Native TCP Delta Stream Socket Syncs |
| **Storage** | Flat files on physical disk | Distributed Erlang Mnesia Database |
| **Agent Context** | Manual regex filtering | SEDM decay-scored node retrieval (`utility = e^(-λt)`) |

---

## Architecture

```
8d Umbrella Application
├── eight_d_core        — Cryptography, Merkle-DAG, CRDT, Storage, VFS
│   ├── Crypto.Blake3   (Rust NIF bindings for extreme throughput)
│   ├── Crypto.Ed25519  (Node signing & cryptographic provenance)
│   ├── MerkleDAG.Node  (Immutable, signed, content-addressed commits)
│   ├── MerkleDAG.DAG   (GenServer tracking exact active frontier branch nodes)
│   ├── CRDT.VectorClock(Causal ordering for concurrent agent executions)
│   ├── CRDT.MerkleCRDT (Mathematical Set-Union merge semantics)
│   ├── Storage.Mnesia  (Persistent graph nodes, raw blobs, and VFS tree tables)
│   └── Storage.VFS     (Recursive active workspace tree → Merkle Tree generator)
│
├── eight_d_cognitive   — Agent memory interface
│   ├── Memory.GCCPrimitives  (Branching and memory extraction boundaries)
│   ├── Memory.DecayEngine    (Exponential half-life context relevance calculations)
│   └── VFS.Projection        (Generates runtime artifacts for agent inputs)
│
├── eight_d_swarm       — Multi-agent orchestration
│   ├── Orchestrator.Coordinator  (Goal decomposition bounds)
│   ├── Orchestrator.Implementor  (Execution sandboxes)
│   ├── Orchestrator.Verifier     (Automated semantic conflict resolver)
│   └── MCP.Server                (Model Context Protocol JSON-RPC API layer)
│
└── eight_d_cli         — Human & agent CLI interface
    └── CLI             (init / commit / branch / log / status / diff / consolidate / serve / sync)
```

---

## Technical Guarantees

| Property | Implementation Mechanism |
|---|---|
| **Content Integrity** | Every node hash explicitly covers its payload, parent pathing, vector clock tick, and identity key execution. |
| **Tamper Detection** | `Node.verify/2` fully re-derives hashes matching Ed25519 signatures. Any alteration invalidates the topological pathing immediately. |
| **Causal Ordering** | Time-based overrides are ignored in favor of `VectorClock` logical tracking enforcing true path causality. |
| **Absolute Convergence** | Merkle Set-Union CRDT ensures that any disconnected peer merges are inherently commutative, associative, and idempotent. |
| **Safe Delta Syncs** | Connecting peers explicitly share frontier tips leading to isolated intersection diffs traversing raw network TCP pipes. |
| **Data Preservation** | Mnesia disc_copies physically encode the Erlang ETS stores to persistent `.8d/` local repositories. |

---

## Production Installation

### Prerequisites
- Elixir 1.15+ / OTP 26+
- Rust toolchain (required for dynamic BLAKE3 C-language ABI compilations)

```bash
# Clone the repository
git clone https://github.com/8dazo/8d.git
cd 8d

# Fetch external components and build libraries natively
mix deps.get && mix compile

# Build a fully standalone production release package integrating native NIFs
mix release

# Use the bundled CLI interface
./_build/dev/rel/eight_d/bin/eight_d --help
```

---

## CLI Usage

All human & agent interface commands operate natively out of the project repository tracking directory (`.8d`):

```bash
# Initialize a new 8d repository footprint
./8d init
# → Bootstraps `.8d/mnesia/` state machine
# → Generates and bounds an Ed25519 keypair inside `.8d/identity`
# → Commits Genesis node onto the exact working tree

# Track agent context state
./8d status
# → Diffs real active tracked workspaces using live BLAKE3 hashes

# Capture agent work iterations locally
./8d commit -m "Extracted user verification logic"
# → Committed [a1b2c3d4]: Extracted user verification logic

# Understand temporal relevancy of execution nodes
./8d log
# → [timestamp] [Agent: local_user] [Score: 0.993] (Hash: a1b2c3d4)
# → Payload: %{type: :work, data: "...", tree_hash: "..."}

# Merge branching execution paths cleanly
./8d consolidate <hash_1> <hash_2>
# → Merge successful according to Set-Union CRDT rules: [merged_hash]
```

---

## TCP Mesh Subsystem (For Distributed Agent Pods)

8d avoids the crippling "split-brain" limitations of distributed database applications by leveraging disconnected, stateless TCP Delta Pushing natively identical to Git, but using binary DAG sets. Erlang nodes remain fully independent.

```bash
# On Host Origin (Terminal 1)
./8d serve 8080
# → Actively launching TCP daemon bound to active DAG graphs...

# On Host Replica (Terminal 2)
./8d sync 127.0.0.1 8080
# → Calculating frontier intersection...
# → Fetched exactly 1 node arrays missing from local graph...
# → Applying TCP logical merges flawlessly.
```

---

## Open Tasks & Extensibility Roadmap

While the underlying synchronization, native OS integration, CLI abstractions, and CRDT logical models are fully complete and production-hardened, `8d` is extensible out-of-the-box:

- **LLM Verification Hook:** The `Verifier` semantic logic boundary requires an explicit call-out to `OpenAI` or `Anthropic` to perform dynamic context merging based on file delta differences rather than hardcoded heuristics.
- **MCP Expansion:** Add the `Diff` and `Sync` TCP commands explicitly into the `.cursor/` AI context via the open MCP socket loop in `eight_d_swarm/lib/mcp/server.ex`.

---

## License

MIT — See [LICENSE](LICENSE)
