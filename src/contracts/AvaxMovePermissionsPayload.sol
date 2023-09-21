// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract AvaxMovePermissionsPayload {
  // ~ 20 proposals
  uint256 public constant AVAX_AMOUNT = 120 ether;
  uint256 public constant LINK_AMOUNT = 122 ether;

  function execute() external {
    // CC FUNDING
    MigratorLib.fundCrosschainController(
      AaveV3Avalanche.COLLECTOR,
      AaveV3Avalanche.POOL,
      GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER,
      AaveV3AvalancheAssets.WAVAX_A_TOKEN,
      AVAX_AMOUNT,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      AaveV3AvalancheAssets.LINKe_A_TOKEN,
      LINK_AMOUNT,
      true
    );

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV2Avalanche.ORACLE,
      AaveV2Avalanche.LENDING_RATE_ORACLE,
      AaveV2Avalanche.WETH_GATEWAY,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY
    );
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV3Avalanche.ACL_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV3Avalanche.EMISSION_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Avalanche.COLLECTOR,
      AaveMisc.PROXY_ADMIN_AVALANCHE,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3Avalanche.SWAP_COLLATERAL_ADAPTER,
      AaveV3Avalanche.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Avalanche.WITHDRAW_SWAP_ADAPTER
    );

    // Proof of reserve
    IOwnable(AaveV2Avalanche.PROOF_OF_RESERVE).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );

    IOwnable(AaveV3Avalanche.PROOF_OF_RESERVE).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
    // one per network
    IOwnable(AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
  }
}
