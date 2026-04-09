# 8d Architecture & Documentation

## The Problem with Git
Git relies on file-level locks (`index.lock`) and character-based diffs. In a multi-agent system, hundreds of agents acting simultaneously cause high lock contention and context degradation.

## The Solution: CASM (Causal Agentic State Manager)
**8d** is an Agent-Native Git Alternative utilizing a 3-tier architecture.

### Tier 1: Cryptographic Substrate
- **Merkle-DAG**: Content-addressable. Every state mutation is an immutable block.
- **CRDT (Conflict-Free Replicated Data Type)**: Delta-state CRDTs guarantee mathematical convergence across concurrent agent branches using simple set-union logic.
- **Vector Clock**: Prevents race conditions and determines causality.
- **Storage**: Real-time sync via Erlang's Mnesia database.

### Tier 2: Cognitive Engine (GCC & SEDM)
- **Git-Context-Controller (GCC)**: Memory primitives `BRANCH`, `COMMIT`, `CONSOLIDATE`, `RETRIEVE`.
- **SEDM (Scalable Self-Evolving Distributed Memory)**: Geometric decay engine that filters low-utility inputs and prevents context-window degradation for the LLM.

### Tier 3: Swarm Orchestration
- **Model Context Protocol (MCP)**: Server standardizing IO.
- **Workflow**: Coordinator sets roadmap. Implementors work. Verifiers do semantic merge over multiple branches.
- **Grid-Cell Correlation Discounting (GCCD)**: Mathematically discounts redundant hallucinated data.

## Elixir Advantages
- **Lightweight Processes**: Native actor model maps perfectly to independent agents. No shared state = no `index.lock`.
- **OTP Supervision**: Fault isolation.
- **Native DB**: Mnesia allows built-in CRDT data storage.
