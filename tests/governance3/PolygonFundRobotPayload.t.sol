// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {PolygonMovePermissionsPayload} from '../../src/contracts/governance2.5/PolygonMovePermissionsPayload.sol';
import {PolygonFundRobotPayload} from '../../src/contracts/governance3/PolygonFundRobotPayload.sol';

contract PolygonFundRobotPayloadTest is Test {
  address public constant ERC677_LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  PolygonFundRobotPayload public payload;
  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 49290337);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPayload() public {
    PolygonMovePermissionsPayload permissionsPayload = new PolygonMovePermissionsPayload();

    payload = new PolygonFundRobotPayload();

    GovHelpers.executePayload(
      vm,
      address(permissionsPayload),
      AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR
    );
    GovHelpers.executePayload(vm, address(payload), GovernanceV3Polygon.EXECUTOR_LVL_1);

    _testRobot();
  }

  function _testRobot() internal {
    uint256 votingChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          KEEPER_REGISTRY,
          uint32(registryState.nonce + 1)
        )
      )
    );

    (address votingChainKeeperTarget, , , uint96 keeperBalance, , , , ) = IKeeperRegistry(
      KEEPER_REGISTRY
    ).getUpkeep(votingChainKeeperId);

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Polygon.EXECUTOR_LVL_1);
    assertEq(votingChainKeeperTarget, payload.VOTING_CHAIN_ROBOT());
    assertEq(uint256(keeperBalance), payload.LINK_AMOUNT_ROBOT_VOTING_CHAIN());

    assertApproxEqAbs(
      IERC20(payload.ERC677_LINK()).balanceOf(payload.ROOTS_CONSUMER()),
      payload.LINK_AMOUNT_ROOTS_CONSUMER(),
      0.2 ether
    );
  }
}
