// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Metis, AaveV3MetisAssets} from 'aave-address-book/AaveV3Metis.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {MetisMovePermissionsPayload} from '../src/contracts/MetisMovePermissionsPayload.sol';
import {IPoolAddressProviderRegistry} from './helpers/IPoolAddressProviderRegistry.sol';
import {IEmissionManager} from './helpers/IEmissionManager.sol';

contract MetisMovePermissionsPayloadTest is MovePermissionsTestBase {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('metis'), 8140311);
  }

  function testPermissionsTransfer() public {
    MetisMovePermissionsPayload payload = new MetisMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.METIS_BRIDGE_EXECUTOR);

    vm.startPrank(payload.METIS_LEVEL_1_EXECUTOR_V3());

    _testV3(
      payload.METIS_LEVEL_1_EXECUTOR_V3(),
      AaveV3Metis.POOL_ADDRESSES_PROVIDER,
      AaveV3Metis.COLLECTOR,
      AaveV3MetisAssets.mDAI_UNDERLYING,
      AaveV3MetisAssets.mDAI_A_TOKEN,
      AaveV3MetisAssets.mDAI_ORACLE,
      AaveV3Metis.EMISSION_MANAGER,
      AaveV3Metis.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_METIS
    );

    vm.stopPrank();
  }
}
