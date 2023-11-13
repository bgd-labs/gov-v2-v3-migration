// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {IExecutor as IExecutorV2} from '../../src/contracts/dependencies/IExecutor.sol';
import {Mediator} from '../../src/contracts/governance3/Mediator.sol';
import {EthLongV3Payload} from '../../src/contracts/governance3/EthLongV3Payload.sol';

contract EthLongV3PayloadTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18562187);
  }

  function testPayload() public {
    Mediator mediator = new Mediator();

    EthLongV3Payload payload = new EthLongV3Payload(address(mediator));

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.LONG_EXECUTOR);

    assertEq(IOwnable(MiscEthereum.PROXY_ADMIN_LONG).owner(), address(mediator));

    assertEq(
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getPendingAdmin(),
      GovernanceV3Ethereum.EXECUTOR_LVL_2
    );

    assertEq(IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).owner(), address(mediator));
  }
}
