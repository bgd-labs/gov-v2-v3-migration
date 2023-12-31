// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {OptMovePermissionsPayload} from '../../src/contracts/governance2.5/OptMovePermissionsPayload.sol';

contract OptMovePermissionsPayloadTest is MovePermissionsTestBase {
  address public KEEPER_REGISTRY = 0x75c0530885F385721fddA23C539AF3701d6183D4;

  OptMovePermissionsPayload public payload;

  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('optimism'), 111233543);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPermissionsTransfer() public {
    payload = new OptMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR);

    vm.startPrank(GovernanceV3Optimism.EXECUTOR_LVL_1);

    _testV3(
      GovernanceV3Optimism.EXECUTOR_LVL_1,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER,
      AaveV3Optimism.COLLECTOR,
      AaveV3OptimismAssets.DAI_UNDERLYING,
      AaveV3OptimismAssets.DAI_A_TOKEN,
      AaveV3OptimismAssets.DAI_ORACLE,
      AaveV3Optimism.EMISSION_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER_REGISTRY,
      MiscOptimism.PROXY_ADMIN
    );

    _testV3Optional(
      GovernanceV3Optimism.EXECUTOR_LVL_1,
      AaveV3Optimism.WETH_GATEWAY,
      AaveV3Optimism.SWAP_COLLATERAL_ADAPTER,
      AaveV3Optimism.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Optimism.WITHDRAW_SWAP_ADAPTER,
      AaveV3Optimism.DEBT_SWAP_ADAPTER
    );

    vm.stopPrank();
  }

  function testRobotMigration() public {
    payload = new OptMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR);

    uint256 executionChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(blockhash(block.number - 1), KEEPER_REGISTRY, uint32(registryState.nonce))
      )
    );

    (address executionChainKeeperTarget, , , uint96 keeperBalance, , , , ) = IKeeperRegistry(
      KEEPER_REGISTRY
    ).getUpkeep(executionChainKeeperId);

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Optimism.EXECUTOR_LVL_1);
    assertEq(executionChainKeeperTarget, payload.EXECUTION_CHAIN_ROBOT());
    assertApproxEqAbs(uint256(keeperBalance), payload.LINK_AMOUNT_ROBOT_EXECUTION_CHAIN(), 0.2 ether);
  }
}
