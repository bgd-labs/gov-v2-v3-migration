// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Avalanche, AaveV2AvalancheAssets} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AvaxMovePermissionsPayload} from '../src/contracts/AvaxMovePermissionsPayload.sol';
import {IKeeperRegistry} from '../src/contracts/dependencies/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IProofOfReserveExecutor} from './helpers/IProofOfReserveExecutor.sol';
import {IProofOfReserveAggregator} from './helpers/IProofOfReserveAggregator.sol';

contract AvaxMovePermissionsPayloadTest is MovePermissionsTestBase {
  address constant AVALANCHE_GUARDIAN = 0xa35b76E4935449E33C56aB24b23fcd3246f13470;

  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  address public LINK_WHALE = 0x3801582a0A8D4138333f7f1322477Aa232093990;

  AvaxMovePermissionsPayload public payload;
  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('avalanche'), 35727962);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPayload() public {
    payload = new AvaxMovePermissionsPayload();

    // expect the collector to have sufficient link tokens during payload execution
    vm.startPrank(LINK_WHALE);
    IERC20(AaveV3AvalancheAssets.LINKe_A_TOKEN).transfer(
      address(AaveV3Avalanche.COLLECTOR),
      payload.TOTAL_LINK_AMOUNT()
    );
    vm.stopPrank();

    GovHelpers.executePayload(vm, address(payload), AVALANCHE_GUARDIAN);

    vm.startPrank(GovernanceV3Avalanche.EXECUTOR_LVL_1);

    _testV2(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2AvalancheAssets.WBTCe_UNDERLYING,
      AaveV2AvalancheAssets.WBTCe_ORACLE,
      AaveV2Avalanche.WETH_GATEWAY,
      address(0),
      address(0),
      AaveV2Avalanche.DEBT_SWAP_ADAPTER
    );

    _testV3(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV3Avalanche.COLLECTOR,
      AaveV3AvalancheAssets.DAIe_UNDERLYING,
      AaveV3AvalancheAssets.DAIe_A_TOKEN,
      AaveV3AvalancheAssets.DAIe_ORACLE,
      AaveV3Avalanche.EMISSION_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_AVALANCHE
    );

    _testV3Optional(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3Avalanche.SWAP_COLLATERAL_ADAPTER,
      AaveV3Avalanche.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Avalanche.WITHDRAW_SWAP_ADAPTER,
      AaveV3Avalanche.DEBT_SWAP_ADAPTER
    );

    _testProofOfReserve();

    _testCrosschainFunding(
      GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER,
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      payload.AVAX_AMOUNT_CROSSCHAIN_CONTROLLER(),
      payload.LINK_AMOUNT_CROSSCHAIN_CONTROLLER()
    );

    _testRobot();

    vm.stopPrank();
  }

  function _testProofOfReserve() internal {
    address[] memory assets = new address[](1);

    assets[0] = AaveV2AvalancheAssets.WBTCe_UNDERLYING;

    // Proof or reserve executor
    IProofOfReserveExecutor(AaveV2Avalanche.PROOF_OF_RESERVE).disableAssets(assets);

    // Proof or reserve executor
    IProofOfReserveExecutor(AaveV3Avalanche.PROOF_OF_RESERVE).disableAssets(assets);

    // Proof or reserve aggregator
    IProofOfReserveAggregator(AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR)
      .disableProofOfReserveFeed(AaveV3AvalancheAssets.AAVEe_UNDERLYING);
  }

  function _testRobot() internal {
    uint256 votingChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          KEEPER_REGISTRY,
          uint32(registryState.nonce)
        )
      )
    );
    uint256 executionChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          KEEPER_REGISTRY,
          uint32(registryState.nonce + 1)
        )
      )
    );

    (address votingChainKeeperTarget, , , , , , , ) = IKeeperRegistry(KEEPER_REGISTRY).getUpkeep(
      votingChainKeeperId
    );
    (address executionChainKeeperTarget, , , , , , , ) = IKeeperRegistry(KEEPER_REGISTRY).getUpkeep(
      executionChainKeeperId
    );

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Avalanche.EXECUTOR_LVL_1);
    assertEq(votingChainKeeperTarget, payload.VOTING_CHAIN_ROBOT());
    assertEq(executionChainKeeperTarget, payload.EXECUTION_CHAIN_ROBOT());

    assertEq(
      payload.LINK_AMOUNT_ROOTS_CONSUMER(),
      IERC20(AaveV3AvalancheAssets.LINKe_UNDERLYING).balanceOf(payload.ROOTS_CONSUMER())
    );
  }
}
