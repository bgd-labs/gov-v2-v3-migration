// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {Executor} from 'aave-governance-v3/contracts/payloads/Executor.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';

contract EthLongMovePermissionsPayloadTest is Test {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 17279232);
  }

  function testPayload() public {
    Executor newExecutor = new Executor();
    Ownable(newExecutor).transferOwnership(AaveGovernanceV2.LONG_EXECUTOR);

    EthLongMovePermissionsPayload payload = new EthLongMovePermissionsPayload(
      address(newExecutor)
    );

    GovHelpers.executePayload(
      vm,
      address(payload),
      AaveGovernanceV2.LONG_EXECUTOR
    );

    vm.startPrank(payload.LEVEL_2_EXECUTOR_V3());

    assertEq(
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getAdmin(),
      payload.LEVEL_2_EXECUTOR_V3()
    );

    assertEq(
      Ownable(payload.LEVEL_2_EXECUTOR_V3()).owner(),
      payload.PAYLOAD_CONTROLLER()
    );

    vm.stopPrank();
  }
}
