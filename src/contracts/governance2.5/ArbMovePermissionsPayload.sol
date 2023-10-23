// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {MigratorLib} from './MigratorLib.sol';

/**
 * @title ArbMovePermissionsPayload
 * @notice Migrate permissions for Aave Pool V3 on Arbitrum from governance v2 to v3.
 * @author BGD Labs
 **/
contract ArbMovePermissionsPayload {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  uint256 public constant GOV_V2_ROBOT_ID =
    99910557623747840434738249049159754336730253966084942174349501874329868147502;

  address public constant ROBOT_OPERATOR = 0xb0A73671C97BAC9Ba899CD1a23604Fd2278cD02A;

  address public constant EXECUTION_CHAIN_ROBOT = 0x64093fe5f8Cf62aFb4377cf7EF4373537fe9155B;

  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 50 ether;

  function execute() external {
    // GET LINK TOKENS FROM COLLECTOR
    MigratorLib.fetchLinkTokens(
      AaveV3Arbitrum.COLLECTOR,
      address(AaveV3Arbitrum.POOL),
      AaveV3ArbitrumAssets.LINK_UNDERLYING,
      AaveV3ArbitrumAssets.LINK_A_TOKEN,
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN,
      true
    );

    // ROBOT
    migrateKeepers();

    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Arbitrum.EXECUTOR_LVL_1,
      AaveV3Arbitrum.ACL_MANAGER,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
      AaveV3Arbitrum.EMISSION_MANAGER,
      AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Arbitrum.COLLECTOR,
      MiscArbitrum.PROXY_ADMIN_ARBITRUM,
      AaveV3Arbitrum.WETH_GATEWAY,
      AaveV3Arbitrum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.WITHDRAW_SWAP_ADAPTER,
      AaveV3Arbitrum.DEBT_SWAP_ADAPTER
    );
  }

  function migrateKeepers() internal {
    uint256 linkBalance = IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).balanceOf(address(this));

    // CANCEL PREVIOUS KEEPER
    IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

    // REGISTER NEW EXECUTION CHAIN KEEPER
    IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).forceApprove(ROBOT_OPERATOR, linkBalance);

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Execution Chain Keeper',
      EXECUTION_CHAIN_ROBOT,
      5000000,
      linkBalance.toUint96()
    );

    // TRANSFER PERMISSION OF ROBOT OPERATOR
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Arbitrum.EXECUTOR_LVL_1);
  }
}
