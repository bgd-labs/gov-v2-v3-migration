// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {ArbMovePermissionsPayload} from '../../src/contracts/governance2.5/ArbMovePermissionsPayload.sol';

contract ArbMovePermissionsPayloadTest is MovePermissionsTestBase {
  address public KEEPER_REGISTRY = 0x75c0530885F385721fddA23C539AF3701d6183D4;

  ArbMovePermissionsPayload public payload;

  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('arbitrum'), 135126485);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPermissionsTransfer() public {
    payload = new ArbMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR);

    vm.startPrank(GovernanceV3Arbitrum.EXECUTOR_LVL_1);

    _testV3(
      GovernanceV3Arbitrum.EXECUTOR_LVL_1,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
      AaveV3Arbitrum.COLLECTOR,
      AaveV3ArbitrumAssets.DAI_UNDERLYING,
      AaveV3ArbitrumAssets.DAI_A_TOKEN,
      AaveV3ArbitrumAssets.DAI_ORACLE,
      AaveV3Arbitrum.EMISSION_MANAGER,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      MiscArbitrum.PROXY_ADMIN
    );

    _testV3Optional(
      GovernanceV3Arbitrum.EXECUTOR_LVL_1,
      AaveV3Arbitrum.WETH_GATEWAY,
      AaveV3Arbitrum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.WITHDRAW_SWAP_ADAPTER,
      AaveV3Arbitrum.DEBT_SWAP_ADAPTER
    );

    vm.stopPrank();
  }

  function testRobotMigration() public {
    payload = new ArbMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR);

    uint256 executionChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(blockhash(block.number - 1), KEEPER_REGISTRY, uint32(registryState.nonce))
      )
    );

    (address executionChainKeeperTarget, , , uint96 keeperBalance, , , , ) = IKeeperRegistry(
      KEEPER_REGISTRY
    ).getUpkeep(executionChainKeeperId);

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Arbitrum.EXECUTOR_LVL_1);
    assertEq(executionChainKeeperTarget, payload.EXECUTION_CHAIN_ROBOT());
    assertGe(uint256(keeperBalance), payload.LINK_AMOUNT_ROBOT_EXECUTION_CHAIN());
  }
}
