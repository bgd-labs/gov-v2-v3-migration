// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Base, AaveV3BaseAssets} from 'aave-address-book/AaveV3Base.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {BaseMovePermissionsPayload} from '../../src/contracts/governance2.5/BaseMovePermissionsPayload.sol';

contract BaseMovePermissionsPayloadTest is MovePermissionsTestBase {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('base'), 4594609);
  }

  function testPermissionsTransfer() public {
    BaseMovePermissionsPayload payload = new BaseMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.BASE_BRIDGE_EXECUTOR);

    vm.startPrank(GovernanceV3Base.EXECUTOR_LVL_1);

    _testV3(
      GovernanceV3Base.EXECUTOR_LVL_1,
      AaveV3Base.POOL_ADDRESSES_PROVIDER,
      AaveV3Base.COLLECTOR,
      AaveV3BaseAssets.USDbC_UNDERLYING,
      AaveV3BaseAssets.USDbC_A_TOKEN,
      AaveV3BaseAssets.USDbC_ORACLE,
      AaveV3Base.EMISSION_MANAGER,
      AaveV3Base.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_BASE
    );

    _testV3Optional(
      GovernanceV3Base.EXECUTOR_LVL_1,
      AaveV3Base.WETH_GATEWAY,
      address(0),
      address(0),
      address(0),
      AaveV3Base.DEBT_SWAP_ADAPTER
    );

    vm.stopPrank();
  }
}
