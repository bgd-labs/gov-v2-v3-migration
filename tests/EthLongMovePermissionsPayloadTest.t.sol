// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {Executor} from 'aave-governance-v3/contracts/payloads/Executor.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {Mediator} from '../src/contracts/Mediator.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';

contract EthLongMovePermissionsPayloadTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 18113580);
  }

  function testPayload() public {
    vm.startPrank(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER));
    Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(AaveGovernanceV2.LONG_EXECUTOR);
    vm.stopPrank();

    Mediator mediator = new Mediator();
    EthLongMovePermissionsPayload payload = new EthLongMovePermissionsPayload(address(mediator));

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.LONG_EXECUTOR);

    assertEq(Ownable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).owner(), address(mediator));

    assertEq(
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getPendingAdmin(),
      GovernanceV3Ethereum.EXECUTOR_LVL_2
    );

    assertEq(Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).owner(), address(mediator));
  }
}
