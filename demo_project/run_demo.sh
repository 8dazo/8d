#!/usr/bin/env bash
# End-to-End Simulation of 8d (Agent-Native Version Control)

cd ../apps/eight_d_cli

echo "=== 1. Starting Swarm Simulation Project ==="
echo "(Cleaning previous repository state for fresh demo)"
rm -rf .8d


# 2. Initialization
echo ""
echo "=== 2. Coordinator: Initializing Repository ==="
mix run -e "EightDCli.CLI.main(~w(init))"

# 3. Agent Submissions (Commits)
echo ""
echo "=== 3. Agents: Injecting Asynchronous Thoughts/Changes ==="
echo "CREATE TABLE users();" > schema.sql
mix run -e 'EightDCli.CLI.main(["commit", "-m", "Implementor-A: Add user authentication schema"])'
sleep 1

mkdir -p src
echo "def router, do: :ok" > src/auth.ex
mix run -e 'EightDCli.CLI.main(["commit", "-m", "Implementor-B: Create OAuth router endpoints"])'
sleep 1

echo "-- Added index" >> schema.sql
echo "Checking dirty workspace via status/diff..."
mix run -e 'EightDCli.CLI.main(~w(status))'
mix run -e 'EightDCli.CLI.main(~w(diff))'

mix run -e 'EightDCli.CLI.main(["commit", "-m", "Coordinator: Update Roadmap context for frontend integrations"])'
mix run -e 'EightDCli.CLI.main(~w(status))'

# 4. View State
echo ""
echo "=== 4. Verifier: Assessing Global DAG Frontier ==="
mix run -e 'EightDCli.CLI.main(~w(branch))'

# 5. Semantic Log History
echo ""
echo "=== 5. LLM Context Retrieval (VFS Projection via SEDM) ==="
mix run -e 'EightDCli.CLI.main(~w(log))'

# 6. Branch Consolidation
echo ""
echo "=== 6. Swarm Merge: Consolidating Independent Forks ==="
mix run -e 'EightDCli.CLI.main(~w(consolidate d3adbeef c0ffee))'

echo ""
echo "=== Demo Complete! ==="
