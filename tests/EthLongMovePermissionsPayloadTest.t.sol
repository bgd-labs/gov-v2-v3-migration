// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {Executor} from 'aave-governance-v3/contracts/payloads/Executor.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';

contract EthLongMovePermissionsPayloadTest is Test {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 18035350);
  }

  function testPayload() public {
    vm.startPrank(GovernanceV3Ethereum.PAYLOADS_CONTROLLER);
    Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(AaveGovernanceV2.LONG_EXECUTOR);
    vm.stopPrank();

    EthLongMovePermissionsPayload payload = new EthLongMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.LONG_EXECUTOR);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_2);

    assertEq(
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getAdmin(),
      GovernanceV3Ethereum.EXECUTOR_LVL_2
    );

    assertEq(
      Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).owner(),
      GovernanceV3Ethereum.PAYLOADS_CONTROLLER
    );

    // test tokens could be redeployed

    vm.stopPrank();
  }
}
