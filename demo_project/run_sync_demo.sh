#!/bin/bash
# 8d Distributed Sync Demonstration

cd /Users/d3v1/projects/8d/demo_project
rm -rf sync_demo
mkdir -p sync_demo/peer_A
mkdir -p sync_demo/peer_B

echo "=== 1. Bootstrapping Peer A ==="
cd /Users/d3v1/projects/8d
mix run -e 'EightDCli.CLI.main(~w(--cwd demo_project/sync_demo/peer_A init))'
echo "Initial Data" > demo_project/sync_demo/peer_A/README.md
mix run -e 'EightDCli.CLI.main(["--cwd", "demo_project/sync_demo/peer_A", "commit", "-m", "Host: Add README"])'

# We launch the server in the background
echo "=== 2. Starting Peer A Daemon (Port 8080) ==="
mix run -e 'EightDCli.CLI.main(["--cwd", "demo_project/sync_demo/peer_A", "serve", "8080"])' &
SERVER_PID=$!
sleep 2

echo "=== 3. Bootstrapping Peer B ==="
mix run -e 'EightDCli.CLI.main(~w(--cwd demo_project/sync_demo/peer_B init))'

echo "=== 4. Peer B: Syncing from Peer A ==="
mix run -e 'EightDCli.CLI.main(["--cwd", "demo_project/sync_demo/peer_B", "sync", "127.0.0.1", "8080"])'
sleep 2

echo "=== 5. Peer B: Checking Merged Logs ==="
mix run -e 'EightDCli.CLI.main(~w(--cwd demo_project/sync_demo/peer_B log))'

kill -9 $SERVER_PID
echo "Distributed Demo Complete!"
