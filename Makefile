# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes
test   :; forge test -vvv

# common
common-flags := --legacy --ledger --mnemonic-indexes $(MNEMONIC_INDEX) --sender $(LEDGER_SENDER) --verify -vvvv --broadcast --slow

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



deploy-owner-mainnet :; forge script scripts/OwnershipUpdate.s.sol:Ethereum --fork-url mainnet $(common-flags)
deploy-owner-polygon :; forge script scripts/OwnershipUpdate.s.sol:Polygon --fork-url polygon $(common-flags)
deploy-owner-avalanche :; forge script scripts/OwnershipUpdate.s.sol:Avalanche --fork-url avalanche $(common-flags)
deploy-owner-arbitrum :; forge script scripts/OwnershipUpdate.s.sol:Arbitrum --fork-url arbitrum $(common-flags)
deploy-owner-optimism :; forge script scripts/OwnershipUpdate.s.sol:Optimism --fork-url optimism $(common-flags)
deploy-owner-base :; forge script scripts/OwnershipUpdate.s.sol:Base --fork-url base $(common-flags)
deploy-owner-metis :; forge script scripts/OwnershipUpdate.s.sol:Metis --fork-url metis $(common-flags)
deploy-owner-gnosis :; forge script scripts/OwnershipUpdate.s.sol:Gnosis --fork-url gnosis $(common-flags)
deploy-owner-binance :; forge script scripts/OwnershipUpdate.s.sol:Binance --fork-url https://rpc.tenderly.co/fork/1eb44d80-5b7a-424c-bc4e-1bd3dfcde83d $(common-flags)



deploy-mainnet :; forge script scripts/DeployV3Payloads.s.sol:DeployMainnet --rpc-url https://rpc.tenderly.co/fork/3625066b-2d1b-49b0-acb3-4fe22cc391eb $(common-flags)
deploy-v2-mainnet :; forge script scripts/DeployV3Payloads.s.sol:DeployV2Mainnet --rpc-url https://rpc.tenderly.co/fork/3625066b-2d1b-49b0-acb3-4fe22cc391eb $(common-flags)
deploy-polygon :; forge script scripts/DeployV3Payloads.s.sol:DeployPolygon  --rpc-url https://rpc.tenderly.co/fork/055d96d7-7612-41a4-aa39-fdedad2a3ba4 $(common-flags)
deploy-avax :; forge script scripts/DeployV3Payloads.s.sol:DeployAvalanche  --rpc-url https://rpc.tenderly.co/fork/e323cdc4-0414-4572-8e8c-1311615881ba $(common-flags)
deploy-base :; forge script scripts/DeployV3Payloads.s.sol:DeployBase  --rpc-url https://rpc.tenderly.co/fork/a92f8e60-6a6d-440a-9067-0d8535fea8b2 $(common-flags)
