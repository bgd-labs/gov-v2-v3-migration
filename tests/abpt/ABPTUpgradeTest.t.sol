// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {IABPT} from './IABPT.sol';
import {ITransparentUpgradeableProxy} from '../../src/contracts/dependencies/ITransparentUpgradeableProxy.sol';
import {IProxyAdmin} from '../../src/contracts/dependencies/IProxyAdmin.sol';
import {IBalancerOwnable} from '../../src/contracts/dependencies/IBalancerOwnable.sol';
import {EthShortMovePermissionsPayload} from '../../src/contracts/governance2.5/EthShortMovePermissionsPayload.sol';
import {ConfigurableRightsPool} from '../../src/ABPT/ABPT.sol';

contract ABPTUpgradeTest is ProtocolV3TestBase {
  address public constant ABPT_PROXY = 0x41A08648C3766F9F9d85598fF102a08f4ef84F84;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18412862);
  }

  function testPayload() public {
    EthShortMovePermissionsPayload shortPayload = new EthShortMovePermissionsPayload();
    ConfigurableRightsPool abpt = new ConfigurableRightsPool();

    // execute 2.5 payload
    GovHelpers.executePayload(vm, address(shortPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    IProxyAdmin(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      ITransparentUpgradeableProxy(address(ABPT_PROXY)),
      address(abpt),
      abi.encodeWithSignature('initialize(address)', GovernanceV3Ethereum.EXECUTOR_LVL_1)
    );

    assertEq(
      IBalancerOwnable(ABPT_PROXY).getController(),
      address(GovernanceV3Ethereum.EXECUTOR_LVL_1)
    );

    IABPT(ABPT_PROXY).setSwapFee(1e16);

    vm.stopPrank();
  }
}
