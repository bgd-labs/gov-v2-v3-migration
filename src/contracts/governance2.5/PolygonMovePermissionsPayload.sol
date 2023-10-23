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
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';
import {IPegSwap} from '../dependencies/IPegSwap.sol';
import {MigratorLib} from '../libraries/MigratorLib.sol';

/**
 * @title AvaxMovePermissionsPayload
 * @notice Migrate permissions for Aave V2 and V3 Pools on Avalanche from governance v2 to v3,
 * fund cross chain controller and gelato.
 * @author BGD Labs
 **/
contract PolygonMovePermissionsPayload {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  address public constant AAVE_MERKLE_DISTRIBUTOR = 0x7A9ff54A6eE4a21223036890bB8c4ea2D62c686b;

  address public constant ERC677_LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 50 ether;

  uint256 public constant GOV_V2_ROBOT_ID =
    5270433258472149004463739312507691937285233476849983113005055156517680660709;

  address public constant ROBOT_OPERATOR = 0x4e8984D11A47Ff89CD67c7651eCaB6C00a74B4A9;

  // ~ 20 proposals
  uint256 public constant MATIC_AMOUNT_CROSSCHAIN_CONTROLLER = 6154 ether;
  uint256 public constant LINK_AMOUNT_CROSSCHAIN_CONTROLLER = 250 ether;

  uint256 public constant TOTAL_LINK_AMOUNT =
    LINK_AMOUNT_CROSSCHAIN_CONTROLLER + LINK_AMOUNT_ROBOT_EXECUTION_CHAIN;

  address public constant GELATO_ADDRESS = 0x73495115E38A307DA3419Bf062bb050b96f68Cf3;
  uint256 public constant GELATO_AMOUNT = 10_000e6;

  IPegSwap public constant PEGSWAP = IPegSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);

  address public constant EXECUTION_CHAIN_ROBOT = 0x249396a890F89D47F89326d7EE116b1d374Fb3A9;

  function execute() external {
    // GELATO FUNDING
    AaveV3Polygon.COLLECTOR.transfer(
      AaveV3PolygonAssets.USDC_A_TOKEN,
      GELATO_ADDRESS,
      GELATO_AMOUNT
    );

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
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      address(0), // by https://polygonscan.com/address/0x46df4eb6f7a3b0adf526f6955b15d3fe02c618b7
      address(0), // by https://polygonscan.com/address/0x05182e579fdfcf69e4390c3411d8fea1fb6467cf
      AaveV2Polygon.DEBT_SWAP_ADAPTER
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
      AaveV3Polygon.WITHDRAW_SWAP_ADAPTER,
      AaveV3Polygon.DEBT_SWAP_ADAPTER
    );

    // MerkleDistributor
    IOwnable(AAVE_MERKLE_DISTRIBUTOR).transferOwnership(GovernanceV3Polygon.EXECUTOR_LVL_1);
  }

  function _fetchLinkTokens() internal {
    // transfer aLINK token from the treasury to the current address
    AaveV3Polygon.COLLECTOR.transfer(
      AaveV3PolygonAssets.LINK_A_TOKEN,
      address(this),
      TOTAL_LINK_AMOUNT
    );

    // withdraw aLINK from the aave pool and receive LINK
    uint256 linkBalance = AaveV3Polygon.POOL.withdraw(
      AaveV3PolygonAssets.LINK_UNDERLYING,
      type(uint256).max,
      address(this)
    );

    // Swap ERC-20 link to ERC-677 link
    IERC20(AaveV3PolygonAssets.LINK_UNDERLYING).forceApprove(address(PEGSWAP), linkBalance);
    PEGSWAP.swap(linkBalance, AaveV3PolygonAssets.LINK_UNDERLYING, ERC677_LINK);
  }

  function migrateKeepers() internal {
    uint256 linkBalance = IERC20(ERC677_LINK).balanceOf(address(this));

    // CANCEL PREVIOUS KEEPER
    IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

    // REGISTER NEW EXECUTION CHAIN KEEPER
    IERC20(ERC677_LINK).forceApprove(ROBOT_OPERATOR, linkBalance);

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Execution Chain Keeper',
      EXECUTION_CHAIN_ROBOT,
      5000000,
      linkBalance.toUint96()
    );

    // TRANSFER PERMISSION OF ROBOT OPERATOR
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Polygon.EXECUTOR_LVL_1);
  }
}
