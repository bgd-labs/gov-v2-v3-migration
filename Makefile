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



deploy-owner-mainnet :; forge script scripts/OwnershipUpdate.s.sol:Ethereum --fork-url mainnet $(common-flags)
deploy-owner-polygon :; forge script scripts/OwnershipUpdate.s.sol:Polygon --fork-url polygon $(common-flags)
deploy-owner-avalanche :; forge script scripts/OwnershipUpdate.s.sol:Avalanche --fork-url avalanche $(common-flags)
deploy-owner-arbitrum :; forge script scripts/OwnershipUpdate.s.sol:Arbitrum --fork-url arbitrum $(common-flags)
deploy-owner-optimism :; forge script scripts/OwnershipUpdate.s.sol:Optimism --fork-url optimism $(common-flags)
deploy-owner-base :; forge script scripts/OwnershipUpdate.s.sol:Base --fork-url base $(common-flags)
deploy-owner-metis :; forge script scripts/OwnershipUpdate.s.sol:Metis --fork-url metis $(common-flags)
deploy-owner-gnosis :; forge script scripts/OwnershipUpdate.s.sol:Gnosis --fork-url gnosis $(common-flags)



deploy-mainnet :; forge script scripts/DeployV3Payloads.s.sol:DeployMainnet --rpc-url https://rpc.tenderly.co/fork/e9279f2c-8033-4a28-b9b8-4465fe50ffbc $(common-flags)
deploy-v2-mainnet :; forge script scripts/DeployV3Payloads.s.sol:DeployV2Mainnet --rpc-url https://rpc.tenderly.co/fork/e9279f2c-8033-4a28-b9b8-4465fe50ffbc $(common-flags)
deploy-polygon :; forge script scripts/DeployV3Payloads.s.sol:DeployPolygon  --rpc-url https://rpc.tenderly.co/fork/a65ea772-1ccb-48b6-8c0b-9fabb3dc07e2 $(common-flags)
deploy-avax :; forge script scripts/DeployV3Payloads.s.sol:DeployAvalanche  --rpc-url https://rpc.tenderly.co/fork/e57f9ba6-2357-4963-a2a3-7cf66cd4f1d3 $(common-flags)
deploy-base :; forge script scripts/DeployV3Payloads.s.sol:DeployBase  --rpc-url https://rpc.tenderly.co/fork/7b18548c-aeff-4013-af55-c4508f14dcdf $(common-flags)
