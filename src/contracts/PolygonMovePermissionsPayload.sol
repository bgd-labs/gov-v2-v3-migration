// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract PolygonMovePermissionsPayload {
  address public constant POLYGON_LEVEL_1_EXECUTOR_V3 = address(6);

  function execute() external {
    // V2 MARKETS
    MigratorLib.migrateV2MarketPermissions(
      POLYGON_LEVEL_1_EXECUTOR_V3,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV2Polygon.ORACLE,
      AaveV2Polygon.LENDING_RATE_ORACLE,
      AaveV2Polygon.WETH_GATEWAY,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY
    );

    // V3 MARKETS
    MigratorLib.migrateV3MarketPermissions(
      POLYGON_LEVEL_1_EXECUTOR_V3,
      AaveV3Polygon.ACL_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV3Polygon.EMISSION_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Polygon.COLLECTOR,
      AaveMisc.PROXY_ADMIN_POLYGON,
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3Polygon.SWAP_COLLATERAL_ADAPTER,
      AaveV3Polygon.REPAY_WITH_COLLATERAL_ADAPTER
    );

    // DefaultIncentivesController - need to be redeployed with the new params
    // Currently permission is held by separate multisig
  }
}
