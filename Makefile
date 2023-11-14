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



deploy-mainnet :; forge script scripts/DeployV3Payloads.s.sol:DeployMainnet --rpc-url https://rpc.tenderly.co/fork/669e1b6f-00e9-4bb2-a217-4b4b66e13f8d $(common-flags)
deploy-v2-mainnet :; forge script scripts/DeployV3Payloads.s.sol:DeployV2Mainnet --rpc-url https://rpc.tenderly.co/fork/669e1b6f-00e9-4bb2-a217-4b4b66e13f8d $(common-flags)
deploy-polygon :; forge script scripts/DeployV3Payloads.s.sol:DeployPolygon  --rpc-url https://rpc.tenderly.co/fork/43d79c07-30f3-4001-af68-ca4c466651a4 $(common-flags)
deploy-avax :; forge script scripts/DeployV3Payloads.s.sol:DeployAvalanche  --rpc-url https://rpc.tenderly.co/fork/816c495a-864e-49b2-b1b7-89688ecadd95 $(common-flags)
deploy-base :; forge script scripts/DeployV3Payloads.s.sol:DeployBase  --rpc-url https://rpc.tenderly.co/fork/c0075b05-3600-456b-864a-d4e3a6c0d9ab $(common-flags)
