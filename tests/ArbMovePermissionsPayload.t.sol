// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ArbMovePermissionsPayload} from '../src/contracts/ArbMovePermissionsPayload.sol';

contract ArbMovePermissionsPayloadTest is MovePermissionsTestBase {
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('arbitrum'), 107373660);
  }

  function testPermissionsTransfer() public {
    ArbMovePermissionsPayload payload = new ArbMovePermissionsPayload();

    GovHelpers.executePayload(
      vm,
      address(payload),
      AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR
    );

    vm.startPrank(payload.ARBITRUM_LEVEL_1_EXECUTOR_V3());

    _testV3(
      payload.ARBITRUM_LEVEL_1_EXECUTOR_V3(),
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
      AaveV3Arbitrum.COLLECTOR,
      AaveV3ArbitrumAssets.DAI_UNDERLYING,
      AaveV3ArbitrumAssets.DAI_A_TOKEN,
      AaveV3ArbitrumAssets.DAI_ORACLE,
      AaveV3Arbitrum.EMISSION_MANAGER,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_ARBITRUM,
      AaveV3Arbitrum.WETH_GATEWAY,
      AaveV3Arbitrum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.REPAY_WITH_COLLATERAL_ADAPTER
    );

    vm.stopPrank();
  }
}
