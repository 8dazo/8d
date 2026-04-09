# 8d Production Roadmap

### Phase 1: Core Hardening (In Progress)
- [ ] Replace SHA-256 with true BLAKE3 using Rustler NIF
- [ ] Ensure Ed25519 identity throughput/correctness
- [ ] Add DAG graph traversal functions (`ancestors`, `diff`)
- [ ] Implement Mnesia Schema Versioning

### Phase 2: CLI Completion
- [x] `init`, `commit`, `branch`, `log`
- [ ] `8d diff`
- [ ] `8d status`
- [ ] `8d consolidate <branch>`
- [ ] `8d sync <peer>`

### Phase 3: Networking & Distribution
- [ ] `libcluster` integration
- [ ] CRDT Delta Sync protocol over TCP

### Phase 4: Agent & MCP Integration
- [ ] Standardize and expose MCP Server routes (`stdio`)
- [ ] DynamicSupervisor Swarm Lifecycle integration

### Phase 5: Verification & Testing
- [ ] Concurrent stress-testing under heavy swarm loads
- [ ] Property-based graph tests using `StreamData`
