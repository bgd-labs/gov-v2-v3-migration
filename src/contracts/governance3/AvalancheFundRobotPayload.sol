// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {RegisterKeepersPayloadBase} from './RegisterKeepersPayloadBase.sol';
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';

import {MigratorLib} from '../libraries/MigratorLib.sol';

/**
 * @title AvalancheFundRobotPayload
 * @notice Fund Robots on Avalanche needed for governance v3.
 * @author BGD Labs
 **/
contract AvalancheFundRobotPayload is RegisterKeepersPayloadBase {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  uint256 public constant LINK_AMOUNT_ROBOT_VOTING_CHAIN = 50 ether;
  uint256 public constant LINK_AMOUNT_ROOTS_CONSUMER = 100 ether;

  uint256 public constant TOTAL_LINK_AMOUNT =
    LINK_AMOUNT_ROBOT_VOTING_CHAIN + LINK_AMOUNT_ROOTS_CONSUMER;

  address public constant ROBOT_OPERATOR = 0x7A9ff54A6eE4a21223036890bB8c4ea2D62c686b;

  address public constant VOTING_CHAIN_ROBOT = 0x10E49034306EaA663646773C04b7B67E81eD0D52;
  address public constant ROOTS_CONSUMER = 0x6264E51782D739caf515a1Bd4F9ae6881B58621b;

  function execute() external {
    // GET LINK TOKENS FROM COLLECTOR
    MigratorLib.fetchLinkTokens(
      AaveV3Avalanche.COLLECTOR,
      address(AaveV3Avalanche.POOL),
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      AaveV3AvalancheAssets.LINKe_A_TOKEN,
      TOTAL_LINK_AMOUNT,
      true
    );

    _registerKeepers(
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN,
      ROBOT_OPERATOR,
      VOTING_CHAIN_ROBOT,
      ROOTS_CONSUMER
    );
  }
}
