// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {IAaveCLRobotOperator} from './dependencies/IAaveCLRobotOperator.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {MigratorLib} from './MigratorLib.sol';

/**
 * @title BaseMovePermissionsPayload
 * @notice Migrate permissions for Aave Pool V3 on Optimism from governance v2 to v3.
 * @author BGD Labs
 **/
contract OptMovePermissionsPayload {
  using SafeCast for uint256;

  uint256 public constant GOV_V2_ROBOT_ID =
    14511291151503490097406614071718050938575520605993697066624566563051111599185;

  address public constant ROBOT_OPERATOR = 0x4f830bc2DdaC99307a3709c85F7533842BdA7c63;

  address public constant EXECUTION_CHAIN_ROBOT = 0xa0195539e21A6553243344A3BE6b874B5d3EC7b9;

  uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 50 ether;

  function execute() external {
    // GET LINK TOKENS FROM COLLECTOR
    MigratorLib.fetchLinkTokens(
      AaveV3Optimism.COLLECTOR,
      address(AaveV3Optimism.POOL),
      AaveV3OptimismAssets.LINK_UNDERLYING,
      AaveV3OptimismAssets.LINK_A_TOKEN,
      LINK_AMOUNT_ROBOT_EXECUTION_CHAIN,
      true
    );

    // ROBOT
    migrateKeepers();

    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Optimism.EXECUTOR_LVL_1,
      AaveV3Optimism.ACL_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER,
      AaveV3Optimism.EMISSION_MANAGER,
      AaveV3Optimism.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Optimism.COLLECTOR,
      AaveMisc.PROXY_ADMIN_OPTIMISM,
      AaveV3Optimism.WETH_GATEWAY,
      AaveV3Optimism.SWAP_COLLATERAL_ADAPTER,
      AaveV3Optimism.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Optimism.WITHDRAW_SWAP_ADAPTER,
      AaveV3Optimism.DEBT_SWAP_ADAPTER
    );
  }

  function migrateKeepers() internal {
    // CANCEL PREVIOUS KEEPER
    IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

    // REGISTER NEW EXECUTION CHAIN KEEPER
    IERC20(AaveV3OptimismAssets.LINK_UNDERLYING).approve(
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
    IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Optimism.EXECUTOR_LVL_1);
  }
}
