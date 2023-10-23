// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Polygon, AaveV2PolygonAssets} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {PolygonMovePermissionsPayload} from '../../src/contracts/governance2.5/PolygonMovePermissionsPayload.sol';

contract PolygonMovePermissionsPayloadTest is MovePermissionsTestBase {
  address public constant ERC677_LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

  address public constant GELATO_ADDRESS = 0x73495115E38A307DA3419Bf062bb050b96f68Cf3;
  uint256 public constant GELATO_AMOUNT = 10_000e6;

  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  PolygonMovePermissionsPayload public payload;
  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 49056415);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPayload() public {
    payload = new PolygonMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);

    vm.startPrank(GovernanceV3Polygon.EXECUTOR_LVL_1);

    _testV2(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2PolygonAssets.WBTC_UNDERLYING,
      AaveV2PolygonAssets.WBTC_ORACLE,
      AaveV2Polygon.WETH_GATEWAY,
      address(0),
      address(0),
      AaveV3Polygon.DEBT_SWAP_ADAPTER
    );

    _testV3(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV3Polygon.COLLECTOR,
      AaveV3PolygonAssets.DAI_UNDERLYING,
      AaveV3PolygonAssets.DAI_A_TOKEN,
      AaveV3PolygonAssets.DAI_ORACLE,
      AaveV3Polygon.EMISSION_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      MiscPolygon.PROXY_ADMIN
    );

    _testV3Optional(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3Polygon.SWAP_COLLATERAL_ADAPTER,
      AaveV3Polygon.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Polygon.WITHDRAW_SWAP_ADAPTER,
      AaveV3Polygon.DEBT_SWAP_ADAPTER
    );

    _testCrosschainFunding(
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      ERC677_LINK,
      payload.MATIC_AMOUNT_CROSSCHAIN_CONTROLLER(),
      payload.LINK_AMOUNT_CROSSCHAIN_CONTROLLER()
    );

    _testGelatoFunding(GELATO_ADDRESS, GELATO_AMOUNT);

    _testRobot();

    vm.stopPrank();
  }

  function _testGelatoFunding(address gelatoAddress, uint256 gelatoAmount) internal {
    uint256 gelatoBalance = IERC20(AaveV3PolygonAssets.USDC_A_TOKEN).balanceOf(gelatoAddress);
    assertEq(gelatoBalance, gelatoAmount);
  }

  function _testRobot() internal {
    uint256 executionChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(blockhash(block.number - 1), KEEPER_REGISTRY, uint32(registryState.nonce))
      )
    );

    (address executionChainKeeperTarget, , , uint96 keeperBalance, , , , ) = IKeeperRegistry(
      KEEPER_REGISTRY
    ).getUpkeep(executionChainKeeperId);

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Polygon.EXECUTOR_LVL_1);
    assertEq(executionChainKeeperTarget, payload.EXECUTION_CHAIN_ROBOT());
    assertApproxEqAbs(uint256(keeperBalance), payload.LINK_AMOUNT_ROBOT_EXECUTION_CHAIN(), 0.1 ether);
  }
}
