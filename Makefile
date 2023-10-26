# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes
test   :; forge test -vvv

# common
common-flags := --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast --slow

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

deploy-mainnet :; forge script scripts/DeployPayloads.s.sol:DeployMainnet --fork-url mainnet --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast
deploy-polygon :; forge script scripts/DeployPayloads.s.sol:DeployPolygon  --rpc-url polygon --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast
deploy-avax :; forge script scripts/DeployPayloads.s.sol:DeployAvalanche  --rpc-url avalanche --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast
deploy-arbitrum :; forge script scripts/DeployPayloads.s.sol:DeployArbitrum  --rpc-url arbitrum --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast
deploy-optimism :; forge script scripts/DeployPayloads.s.sol:DeployOptimism  --rpc-url optimism --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast
deploy-metis :; forge script scripts/DeployPayloads.s.sol:DeployMetis  --rpc-url metis --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast
deploy-base :; forge script scripts/DeployPayloads.s.sol:DeployBase  --rpc-url base --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvv --broadcast



deploy-owner-mainnet :; forge script scripts/OwnershipUpdate.s.sol:Ethereum --fork-url https://rpc.tenderly.co/fork/7f892cc9-0097-4095-8100-0c8f58716e79 $(common-flags)
deploy-owner-polygon :; forge script scripts/OwnershipUpdate.s.sol:Polygon --fork-url https://rpc.tenderly.co/fork/9b23a671-b47b-4d71-8c30-07fb1c8cfb91 $(common-flags)
deploy-owner-avalanche :; forge script scripts/OwnershipUpdate.s.sol:Avalanche --fork-url https://rpc.tenderly.co/fork/54c6fc27-b83d-44fa-bd37-2599008d8ae2 $(common-flags)
deploy-owner-arbitrum :; forge script scripts/OwnershipUpdate.s.sol:Arbitrum --fork-url https://rpc.tenderly.co/fork/35f1ee13-e56e-4db0-b099-18d2c0122353 $(common-flags)
deploy-owner-optimism :; forge script scripts/OwnershipUpdate.s.sol:Optimism --fork-url https://rpc.tenderly.co/fork/27eaa83b-257d-422c-a3db-dcdd10994f26 $(common-flags)
deploy-owner-base :; forge script scripts/OwnershipUpdate.s.sol:Base --fork-url https://rpc.tenderly.co/fork/7954043d-42e1-48a3-acad-cb9641c6da20 $(common-flags)
