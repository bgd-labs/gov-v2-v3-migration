// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IAaveCLRobotOperator} from './dependencies/IAaveCLRobotOperator.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {MigratorLib} from './MigratorLib.sol';

/**
 * @title AvaxMovePermissionsPayload
 * @notice Migrate permissions for Aave V2 and V3 Pools on Avalanche from governance v2 to v3
 * and fund cross chain controller
 * @author BGD Labs
 **/
contract AvaxMovePermissionsPayload {
  using SafeCast for uint256;

  address public constant ROBOT_OPERATOR = 0x7A9ff54A6eE4a21223036890bB8c4ea2D62c686b;

  address public constant AAVE_MERKLE_DISTRIBUTOR = 0xA065d5A299E618CD84a87641d5eEbC7916Fdf32E;

  uint256 public constant LINK_AMOUNT_ROBOT_VOTING_CHAIN = 50 ether;
  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 50 ether;
  uint256 public constant LINK_AMOUNT_ROOTS_CONSUMER = 100 ether;

  // ~ 20 proposals
  uint256 public constant AVAX_AMOUNT_CROSSCHAIN_CONTROLLER = 361 ether;
  uint256 public constant LINK_AMOUNT_CROSSCHAIN_CONTROLLER = 250 ether;

  uint256 public constant TOTAL_LINK_AMOUNT =
    LINK_AMOUNT_CROSSCHAIN_CONTROLLER +
      LINK_AMOUNT_ROBOT_VOTING_CHAIN +
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN +
      LINK_AMOUNT_ROOTS_CONSUMER;

  address public constant VOTING_CHAIN_ROBOT = 0x10E49034306EaA663646773C04b7B67E81eD0D52;
  address public constant EXECUTION_CHAIN_ROBOT = 0x7B74938583Eb03e06042fcB651046BaF0bf15644;
  address public constant ROOTS_CONSUMER = 0x6264E51782D739caf515a1Bd4F9ae6881B58621b;

  function execute() external {
    // CC FUNDING
    MigratorLib.fundCrosschainControllerNative(
      AaveV3Avalanche.COLLECTOR,
      GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER,
      AaveV3AvalancheAssets.WAVAX_A_TOKEN,
      AaveV3AvalancheAssets.WAVAX_UNDERLYING,
      AVAX_AMOUNT_CROSSCHAIN_CONTROLLER,
      address(AaveV3Avalanche.POOL)
    );

    // GET LINK TOKENS FROM COLLECTOR
    MigratorLib.fetchLinkTokens(
      AaveV3Avalanche.COLLECTOR,
      address(AaveV3Avalanche.POOL),
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      AaveV3AvalancheAssets.LINKe_A_TOKEN,
      TOTAL_LINK_AMOUNT,
      true
    );

    // transfer LINK to the CC
    IERC20(AaveV3AvalancheAssets.LINKe_UNDERLYING).transfer(
      GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER,
      LINK_AMOUNT_CROSSCHAIN_CONTROLLER
    );

    // ROBOT
    migrateKeepers();

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV2Avalanche.ORACLE,
      AaveV2Avalanche.LENDING_RATE_ORACLE,
      AaveV2Avalanche.WETH_GATEWAY,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      address(0), // swap collateral adapter owned by https://snowtrace.io/address/0x05182e579fdfcf69e4390c3411d8fea1fb6467cf
      address(0), // repay with collateral adapter owned by https://snowtrace.io/address/0x05182e579fdfcf69e4390c3411d8fea1fb6467cf
      AaveV2Avalanche.DEBT_SWAP_ADAPTER
    );
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV3Avalanche.ACL_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV3Avalanche.EMISSION_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Avalanche.COLLECTOR,
      AaveMisc.PROXY_ADMIN_AVALANCHE,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3Avalanche.SWAP_COLLATERAL_ADAPTER,
      AaveV3Avalanche.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Avalanche.WITHDRAW_SWAP_ADAPTER,
      AaveV3Avalanche.DEBT_SWAP_ADAPTER
    );

    // MerkleDistributor
    IOwnable(AAVE_MERKLE_DISTRIBUTOR).transferOwnership(GovernanceV3Avalanche.EXECUTOR_LVL_1);

    // Proof of reserve
    IOwnable(AaveV2Avalanche.PROOF_OF_RESERVE).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );

    IOwnable(AaveV3Avalanche.PROOF_OF_RESERVE).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
    // one per network
    IOwnable(AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
  }

  function migrateKeepers() internal {
    // REGISTER NEW KEEPER (VOTING CHAIN, EXECUTION CHAIN)
    IERC20(AaveV3AvalancheAssets.LINKe_UNDERLYING).approve(
      ROBOT_OPERATOR,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN + LINK_AMOUNT_ROBOT_EXECUTION_CHAIN
    );

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Voting Chain Keeper',
      VOTING_CHAIN_ROBOT,
      5_000_000,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN.toUint96()
    );
    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Execution Chain Keeper',
      EXECUTION_CHAIN_ROBOT,
      5_000_000,
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN.toUint96()
    );

    // FUND ROOTS CONSUMER
    IERC20(AaveV3AvalancheAssets.LINKe_UNDERLYING).transfer(
      ROOTS_CONSUMER,
      LINK_AMOUNT_ROOTS_CONSUMER
    );

    // TRANSFER PERMISSION OF ROBOT OPERATOR
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Avalanche.EXECUTOR_LVL_1);
  }
}
