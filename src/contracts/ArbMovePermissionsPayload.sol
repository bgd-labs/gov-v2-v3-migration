// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract ArbMovePermissionsPayload {
  function execute() external {
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Arbitrum.EXECUTOR_LVL_1,
      AaveV3Arbitrum.ACL_MANAGER,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
      AaveV3Arbitrum.EMISSION_MANAGER,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Arbitrum.COLLECTOR,
      AaveMisc.PROXY_ADMIN_ARBITRUM,
      AaveV3Arbitrum.WETH_GATEWAY,
      AaveV3Arbitrum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.WITHDRAW_SWAP_ADAPTER
    );
  }
}
