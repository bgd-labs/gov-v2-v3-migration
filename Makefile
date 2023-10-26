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



deploy-owner-mainnet :; forge script scripts/OwnershipUpdate.s.sol:Ethereum --fork-url https://rpc.tenderly.co/fork/7d7f99e5-6262-4c3c-9091-97105205ef9e $(common-flags)
deploy-owner-polygon :; forge script scripts/OwnershipUpdate.s.sol:Polygon --fork-url https://rpc.tenderly.co/fork/72947ef5-f240-4779-bb57-47a3e0eea859 $(common-flags)
deploy-owner-avalanche :; forge script scripts/OwnershipUpdate.s.sol:Avalanche --fork-url https://rpc.tenderly.co/fork/9c3fa99a-86d3-49bf-968b-3327afc21af4 $(common-flags)
deploy-owner-arbitrum :; forge script scripts/OwnershipUpdate.s.sol:Arbitrum --fork-url https://rpc.tenderly.co/fork/1c528f95-485c-4eb2-b134-13eae666ec12 $(common-flags)
deploy-owner-optimism :; forge script scripts/OwnershipUpdate.s.sol:Optimism --fork-url https://rpc.tenderly.co/fork/4bc0a363-f51e-4cf6-987b-fc978a12b0a5 $(common-flags)
deploy-owner-base :; forge script scripts/OwnershipUpdate.s.sol:Base --fork-url https://rpc.tenderly.co/fork/ff293457-810e-4e21-8ec8-37a720fecdda $(common-flags)
