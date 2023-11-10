// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {BaseSwapsPayload} from '../../src/contracts/governance3/BaseSwapsPayload.sol';

contract BaseSwapsPayloadTest is Test {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('base'), 6409632);
  }

  function testPermissionsTransfer() public {
    BaseSwapsPayload payload = new BaseSwapsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.BASE_BRIDGE_EXECUTOR);

    vm.startPrank(GovernanceV3Base.EXECUTOR_LVL_1);

    // ParaSwapLiquiditySwapAdapter
    assertEq(IOwnable(AaveV3Base.SWAP_COLLATERAL_ADAPTER).owner(), GovernanceV3Base.EXECUTOR_LVL_1);

    // ParaSwapRepayAdapter
    assertEq(
      IOwnable(AaveV3Base.REPAY_WITH_COLLATERAL_ADAPTER).owner(),
      GovernanceV3Base.EXECUTOR_LVL_1
    );

    // WithdrawSwapAdapter
    assertEq(IOwnable(AaveV3Base.WITHDRAW_SWAP_ADAPTER).owner(), GovernanceV3Base.EXECUTOR_LVL_1);

    vm.stopPrank();
  }
}
