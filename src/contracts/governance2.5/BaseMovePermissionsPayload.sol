// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';

import {MigratorLib} from '../libraries/MigratorLib.sol';

/**
 * @title BaseMovePermissionsPayload
 * @notice Migrate permissions for Aave Pool V3 on Base from governance v2 to v3.
 * @author BGD Labs
 **/
contract BaseMovePermissionsPayload {
  function execute() external {
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Base.EXECUTOR_LVL_1,
      AaveV3Base.ACL_MANAGER,
      AaveV3Base.POOL_ADDRESSES_PROVIDER,
      AaveV3Base.EMISSION_MANAGER,
      AaveV3Base.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Base.COLLECTOR,
      MiscBase.PROXY_ADMIN,
      AaveV3Base.WETH_GATEWAY,
      address(0), // swap collateral adapter not deployed yet
      address(0), // repay with collateral adapter not deployed yet
      address(0), // withdraw swap adapter not deployed
      AaveV3Base.DEBT_SWAP_ADAPTER
    );
  }
}
