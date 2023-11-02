// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AvaxMovePermissionsPayload} from '../../src/contracts/governance2.5/AvaxMovePermissionsPayload.sol';
import {AvalancheFundRobotPayload} from '../../src/contracts/governance3/AvalancheFundRobotPayload.sol';

contract AvaxMovePermissionsPayloadTest is Test {
  address constant AVALANCHE_GUARDIAN = 0xa35b76E4935449E33C56aB24b23fcd3246f13470;

  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  AvalancheFundRobotPayload public payload;
  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('avalanche'), 37067269);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPayload() public {
    AvaxMovePermissionsPayload permissionsPayload = new AvaxMovePermissionsPayload();
    payload = new AvalancheFundRobotPayload();

    GovHelpers.executePayload(vm, address(permissionsPayload), AVALANCHE_GUARDIAN);
    GovHelpers.executePayload(vm, address(payload), GovernanceV3Avalanche.EXECUTOR_LVL_1);

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

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Avalanche.EXECUTOR_LVL_1);
    assertEq(votingChainKeeperTarget, payload.VOTING_CHAIN_ROBOT());
    assertEq(uint256(keeperBalance), payload.LINK_AMOUNT_ROBOT_VOTING_CHAIN());

    assertApproxEqAbs(
      IERC20(AaveV3AvalancheAssets.LINKe_UNDERLYING).balanceOf(payload.ROOTS_CONSUMER()),
      payload.LINK_AMOUNT_ROOTS_CONSUMER(),
      0.2 ether
    );
  }
}
