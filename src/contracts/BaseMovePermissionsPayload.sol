// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract BaseMovePermissionsPayload {
  address public constant BASE_LEVEL_1_EXECUTOR_V3 = address(6);

  function execute() external {
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      BASE_LEVEL_1_EXECUTOR_V3,
      AaveV3Base.ACL_MANAGER,
      AaveV3Base.POOL_ADDRESSES_PROVIDER,
      AaveV3Base.EMISSION_MANAGER,
      AaveV3Base.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Base.COLLECTOR,
      AaveMisc.PROXY_ADMIN_BASE,
      AaveV3Base.WETH_GATEWAY,
      address(0), // swap collateral adapter not deployed yet
      address(0), // repay with collateral adapter not deployed yet
      address(0) // withdraw swap adapter not deployed
    );
  }
}
