// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';

import {MigratorLib} from './MigratorLib.sol';

/**
 * @title BaseMovePermissionsPayload
 * @notice Migrate permissions for Aave Pool V3 on Optimism from governance v2 to v3.
 * @author BGD Labs
 **/
contract OptMovePermissionsPayload {
  function execute() external {
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Optimism.EXECUTOR_LVL_1,
      AaveV3Optimism.ACL_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER,
      AaveV3Optimism.EMISSION_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Optimism.COLLECTOR,
      AaveMisc.PROXY_ADMIN_OPTIMISM,
      AaveV3Optimism.WETH_GATEWAY,
      AaveV3Optimism.SWAP_COLLATERAL_ADAPTER,
      AaveV3Optimism.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Optimism.WITHDRAW_SWAP_ADAPTER
    );
  }
}
