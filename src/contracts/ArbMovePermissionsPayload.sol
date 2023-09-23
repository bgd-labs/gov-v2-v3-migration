// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IAaveCLRobotOperator} from './dependencies/IAaveCLRobotOperator.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {MigratorLib} from './MigratorLib.sol';

contract ArbMovePermissionsPayload {
  using SafeCast for uint256;

  uint256 public constant GOV_V2_ROBOT_ID =
    99910557623747840434738249049159754336730253966084942174349501874329868147502;

  address public constant ROBOT_OPERATOR = 0xb0A73671C97BAC9Ba899CD1a23604Fd2278cD02A;

  // TODO: update after deploying
  address public constant EXECUTION_CHAIN_ROBOT = 0x864a6Aa4b8D4d84A7570fE2d0E4eCE8077AbcabB;

  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 50 ether;

  function execute() external {
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
      AaveMisc.PROXY_ADMIN_ARBITRUM,
      AaveV3Arbitrum.WETH_GATEWAY,
      AaveV3Arbitrum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Arbitrum.WITHDRAW_SWAP_ADAPTER
    );
  }

  function migrateKeepers() internal {
    // CANCEL PREVIOUS KEEPER
    IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

    // REGISTER NEW EXECUTION CHAIN KEEPER
    IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).approve(
      ROBOT_OPERATOR,
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN
    );

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Execution Chain Keeper',
      EXECUTION_CHAIN_ROBOT,
      5000000,
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN.toUint96()
    );

    // TRANSFER PERMISSION OF ROBOT OPERATOR
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Arbitrum.EXECUTOR_LVL_1);
  }
}
