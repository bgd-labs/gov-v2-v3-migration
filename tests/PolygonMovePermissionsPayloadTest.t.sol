// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Polygon, AaveV2PolygonAssets} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {PolygonMovePermissionsPayload} from '../src/contracts/PolygonMovePermissionsPayload.sol';

contract PolygonMovePermissionsPayloadTest is MovePermissionsTestBase {
  address public constant GELATO_ADDRESS = 0x73495115E38A307DA3419Bf062bb050b96f68Cf3;
  uint256 public constant GELATO_AMOUNT = 10_000e6;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 47447966);
  }

  function testPayload() public {
    PolygonMovePermissionsPayload payload = new PolygonMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);

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
      AaveMisc.PROXY_ADMIN_POLYGON
    );

    _testV3Optional(
      payload.POLYGON_LEVEL_1_EXECUTOR_V3(),
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3Polygon.SWAP_COLLATERAL_ADAPTER,
      AaveV3Polygon.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Polygon.WITHDRAW_SWAP_ADAPTER
    );

    _testCrosschainFunding(
      payload.CROSSCHAIN_CONTROLLER(),
      AaveV3PolygonAssets.LINK_UNDERLYING,
      payload.MATIC_AMOUNT(),
      payload.LINK_AMOUNT()
    );

    _testGelatoFunding(GELATO_ADDRESS, GELATO_AMOUNT);

    vm.stopPrank();
  }

  function _testGelatoFunding(address gelatoAddress, uint256 gelatoAmount) internal {
    uint256 gelatoBalance = IERC20(AaveV3PolygonAssets.USDC_UNDERLYING).balanceOf(gelatoAddress);
    assertEq(gelatoBalance, gelatoAmount);
  }
}
