// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract OptMovePermissionsPayload {
  address public constant OPTIMISM_LEVEL_1_EXECUTOR_V3 = address(5);

  function execute() external {
    // V3 MARKETS
    MigratorLib.migrateV3MarketPermissions(
      OPTIMISM_LEVEL_1_EXECUTOR_V3,
      AaveV3Optimism.ACL_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER,
      AaveV3Optimism.EMISSION_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Optimism.COLLECTOR,
      AaveMisc.PROXY_ADMIN_OPTIMISM,
      AaveV3Optimism.WETH_GATEWAY,
      AaveV3Optimism.SWAP_COLLATERAL_ADAPTER,
      AaveV3Optimism.REPAY_WITH_COLLATERAL_ADAPTER
    );
  }
}
