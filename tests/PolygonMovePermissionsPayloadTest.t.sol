// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Polygon, AaveV2PolygonAssets} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {PolygonMovePermissionsPayload} from '../../src/proposal/PolygonMovePermissionsPayload.sol';

contract PolygonMovePermissionsPayloadTest is MovePermissionsTestBase {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 44626730);
  }

  function testPayload() public {
    PolygonMovePermissionsPayload payload = new PolygonMovePermissionsPayload();

    GovHelpers.executePayload(
      vm,
      address(payload),
      AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR
    );

    vm.startPrank(payload.POLYGON_LEVEL_1_EXECUTOR_V3());

    _testV2(
      payload.POLYGON_LEVEL_1_EXECUTOR_V3(),
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2PolygonAssets.WBTC_UNDERLYING,
      AaveV2PolygonAssets.WBTC_ORACLE,
      AaveV2Polygon.WETH_GATEWAY
    );

    _testV3(
      payload.POLYGON_LEVEL_1_EXECUTOR_V3(),
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV3Polygon.COLLECTOR,
      AaveV3PolygonAssets.DAI_UNDERLYING,
      AaveV3PolygonAssets.DAI_A_TOKEN,
      AaveV3PolygonAssets.DAI_ORACLE,
      AaveV3Polygon.EMISSION_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_POLYGON,
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3Polygon.SWAP_COLLATERAL_ADAPTER,
      AaveV3Polygon.REPAY_WITH_COLLATERAL_ADAPTER
    );

    vm.stopPrank();
  }
}
