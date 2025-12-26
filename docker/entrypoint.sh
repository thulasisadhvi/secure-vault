#!/bin/sh

echo "Compiling Smart Contracts..."
npx hardhat compile

echo "Starting Local Blockchain & Deploying..."
# Start a local hardhat node in the background
npx hardhat node &

# Wait a few seconds for the node to initialize
sleep 5

# Run the deployment script
npx hardhat run scripts/deploy.js --network localhost

# Keep the container running so you can see the logs
tail -f /dev/null