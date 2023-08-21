// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Avalanche, AaveV2AvalancheAssets} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AvaxMovePermissionsPayload} from '../src/contracts/AvaxMovePermissionsPayload.sol';
import {IProofOfReserveExecutor} from './helpers/IProofOfReserveExecutor.sol';
import {IProofOfReserveAggregator} from './helpers/IProofOfReserveAggregator.sol';

contract AvaxMovePermissionsPayloadTest is MovePermissionsTestBase {
  address constant AVALANCHE_GUARDIAN =
    0xa35b76E4935449E33C56aB24b23fcd3246f13470;
  address constant AVALANCHE_LEGACY_GUARDIAN =
    0x01244E7842254e3FD229CD263472076B1439D1Cd;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('avalanche'), 32070190);
  }

  function testPayload() public {
    AvaxMovePermissionsPayload payload = new AvaxMovePermissionsPayload();

    // move ownership of pool admin from the legacy guardian
    vm.startPrank(AVALANCHE_LEGACY_GUARDIAN);
    Ownable(address(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER)).transferOwnership(
      AVALANCHE_GUARDIAN
    );
    vm.stopPrank();

    GovHelpers.executePayload(vm, address(payload), AVALANCHE_GUARDIAN);

    vm.startPrank(payload.AVALANCHE_LEVEL_1_EXECUTOR_V3());

    _testV2(
      payload.AVALANCHE_LEVEL_1_EXECUTOR_V3(),
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2AvalancheAssets.WBTCe_UNDERLYING,
      AaveV2AvalancheAssets.WBTCe_ORACLE,
      AaveV2Avalanche.WETH_GATEWAY
    );

    _testV3(
      payload.AVALANCHE_LEVEL_1_EXECUTOR_V3(),
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV3Avalanche.COLLECTOR,
      AaveV3AvalancheAssets.DAIe_UNDERLYING,
      AaveV3AvalancheAssets.DAIe_A_TOKEN,
      AaveV3AvalancheAssets.DAIe_ORACLE,
      AaveV3Avalanche.EMISSION_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_AVALANCHE,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3Avalanche.SWAP_COLLATERAL_ADAPTER,
      AaveV3Avalanche.REPAY_WITH_COLLATERAL_ADAPTER
    );

    _testProofOfReserve();

    vm.stopPrank();
  }

  function _testProofOfReserve() internal {
    address[] memory assets = new address[](1);

    assets[0] = AaveV2AvalancheAssets.WBTCe_UNDERLYING;

    // Proof or reserve executor
    IProofOfReserveExecutor(AaveV2Avalanche.PROOF_OF_RESERVE).disableAssets(
      assets
    );

    // Proof or reserve executor
    IProofOfReserveExecutor(AaveV3Avalanche.PROOF_OF_RESERVE).disableAssets(
      assets
    );

    // Proof or reserve aggregator
    IProofOfReserveAggregator(AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR)
      .disableProofOfReserveFeed(AaveV3AvalancheAssets.AAVEe_UNDERLYING);
  }
}
