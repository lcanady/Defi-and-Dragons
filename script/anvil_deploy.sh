#!/bin/bash

# Kill any running Anvil instances
pkill -f anvil

# Start Anvil in the background
anvil --block-time 1 &
ANVIL_PID=$!

# Wait for Anvil to start
sleep 2

# Set environment variables for deployment
export ANVIL_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Deploy contracts
forge script script/DeployLocal.s.sol:DeployLocal --broadcast --rpc-url http://localhost:8545

# Load the deployed addresses
source .env.anvil

echo "Local deployment complete! Anvil running with PID: $ANVIL_PID"
echo "To stop Anvil, run: kill $ANVIL_PID" 