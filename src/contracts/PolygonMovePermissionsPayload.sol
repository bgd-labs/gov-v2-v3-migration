// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IAaveCLRobotOperator} from './dependencies/IAaveCLRobotOperator.sol';
import {IPegSwap} from './dependencies/IPegSwap.sol';
import {MigratorLib} from './MigratorLib.sol';

contract PolygonMovePermissionsPayload {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  address public constant ERC677_LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

  uint256 public constant LINK_AMOUNT_ROBOT_VOTING_CHAIN = 50 ether;
  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 50 ether;
  uint256 public constant LINK_AMOUNT_ROOTS_CONSUMER = 100 ether;

  uint256 public constant GOV_V2_ROBOT_ID =
    5270433258472149004463739312507691937285233476849983113005055156517680660709;

  address public constant ROBOT_OPERATOR = 0x4e8984D11A47Ff89CD67c7651eCaB6C00a74B4A9;

  // ~ 20 proposals
  uint256 public constant MATIC_AMOUNT_CROSSCHAIN_CONTROLLER = 6154 ether;
  uint256 public constant LINK_AMOUNT_CROSSCHAIN_CONTROLLER = 250 ether;

  uint256 public constant TOTAL_LINK_AMOUNT =
    LINK_AMOUNT_CROSSCHAIN_CONTROLLER +
      LINK_AMOUNT_ROBOT_VOTING_CHAIN +
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN +
      LINK_AMOUNT_ROOTS_CONSUMER;

  address public constant GELATO_ADDRESS = 0x73495115E38A307DA3419Bf062bb050b96f68Cf3;
  uint256 public constant GELATO_AMOUNT = 10_000e6;

  IPegSwap public constant PEGSWAP = IPegSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);

  // TODO: update after deploying
  address public constant VOTING_CHAIN_ROBOT = 0xDa98B308be8766501ec7Fe3eD9a48EfBD6c31a7B;
  address public constant EXECUTION_CHAIN_ROBOT = 0xDa98B308be8766501ec7Fe3eD9a48EfBD6c31a7B;
  address public constant ROOTS_CONSUMER = 0xDa98B308be8766501ec7Fe3eD9a48EfBD6c31a7B;

  function execute() external {
    // GELATO FUNDING
    AaveV3Polygon.COLLECTOR.transfer(
      AaveV3PolygonAssets.USDC_A_TOKEN,
      address(this),
      GELATO_AMOUNT
    );

    AaveV3Polygon.POOL.withdraw(AaveV3PolygonAssets.USDC_UNDERLYING, GELATO_AMOUNT, GELATO_ADDRESS);

    // CC FUNDING
    MigratorLib.fundCrosschainControllerNative(
      AaveV3Polygon.COLLECTOR,
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      AaveV3PolygonAssets.WMATIC_A_TOKEN,
      MATIC_AMOUNT_CROSSCHAIN_CONTROLLER,
      AaveV3Polygon.WETH_GATEWAY
    );

    _fetchLinkTokens();

    // transfer LINK to the CC
    IERC20(ERC677_LINK).transfer(
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      LINK_AMOUNT_CROSSCHAIN_CONTROLLER
    );

    // ROBOT
    migrateKeepers();

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV2Polygon.ORACLE,
      AaveV2Polygon.LENDING_RATE_ORACLE,
      AaveV2Polygon.WETH_GATEWAY,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY
    );

    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV3Polygon.ACL_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV3Polygon.EMISSION_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Polygon.COLLECTOR,
      AaveMisc.PROXY_ADMIN_POLYGON,
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3Polygon.SWAP_COLLATERAL_ADAPTER,
      AaveV3Polygon.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Polygon.WITHDRAW_SWAP_ADAPTER
    );
  }

  function _fetchLinkTokens() internal {
    // transfer aLINK token from the treasury to the current address
    AaveV3Polygon.COLLECTOR.transfer(
      AaveV3PolygonAssets.LINK_A_TOKEN,
      address(this),
      TOTAL_LINK_AMOUNT
    );

    // withdraw aLINK from the aave pool and receive LINK
    AaveV3Polygon.POOL.withdraw(
      AaveV3PolygonAssets.LINK_UNDERLYING,
      TOTAL_LINK_AMOUNT,
      address(this)
    );

    // Swap ERC-20 link to ERC-677 link
    IERC20(AaveV3PolygonAssets.LINK_UNDERLYING).forceApprove(address(PEGSWAP), TOTAL_LINK_AMOUNT);
    PEGSWAP.swap(TOTAL_LINK_AMOUNT, AaveV3PolygonAssets.LINK_UNDERLYING, ERC677_LINK);
  }

  function migrateKeepers() internal {
    // CANCEL PREVIOUS KEEPER
    IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

    // REGISTER NEW KEEPER (VOTING CHAIN, EXECUTION CHAIN)
    IERC20(ERC677_LINK).approve(
      ROBOT_OPERATOR,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN + LINK_AMOUNT_ROBOT_EXECUTION_CHAIN
    );

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Voting Chain Keeper',
      VOTING_CHAIN_ROBOT,
      5000000,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN.toUint96()
    );
    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Execution Chain Keeper',
      EXECUTION_CHAIN_ROBOT,
      5000000,
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN.toUint96()
    );

    // FUND ROOTS CONSUMER
    IERC20(ERC677_LINK).transfer(ROOTS_CONSUMER, LINK_AMOUNT_ROOTS_CONSUMER);

    // TRANSFER PERMISSION OF ROBOT OPERATOR
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Polygon.EXECUTOR_LVL_1);
  }
}
