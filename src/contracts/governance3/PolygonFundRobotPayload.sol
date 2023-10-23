// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';
import {IPegSwap} from '../dependencies/IPegSwap.sol';

/**
 * @title PolygonFundRobotPayload
 * @notice Fund Robots on Polygon needed for governance v3.
 * @author BGD Labs
 **/
contract PolygonFundRobotPayload {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  uint256 public constant LINK_AMOUNT_ROBOT_VOTING_CHAIN = 50 ether;
  uint256 public constant LINK_AMOUNT_ROOTS_CONSUMER = 100 ether;

  address public constant ERC677_LINK = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

  IPegSwap public constant PEGSWAP = IPegSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);

  uint256 public constant TOTAL_LINK_AMOUNT = LINK_AMOUNT_ROBOT_VOTING_CHAIN + LINK_AMOUNT_ROOTS_CONSUMER;

  address public constant ROBOT_OPERATOR = 0x4e8984D11A47Ff89CD67c7651eCaB6C00a74B4A9;

  address public constant VOTING_CHAIN_ROBOT = 0xbe7998712402B6A63975515A532Ce503437998b7;
  address public constant ROOTS_CONSUMER = 0xE77aF99210AC55939e1ba0bFC6A9a20E1Da73b25;

  function execute() external {
    _fetchLinkTokens();

    _registerKeepers();
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

  function _registerKeepers() internal {
    // REGISTER NEW VOTING CHAIN KEEPER
    IERC20(ERC677_LINK).approve(ROBOT_OPERATOR, LINK_AMOUNT_ROBOT_VOTING_CHAIN);

    IAaveCLRobotOperator(ROBOT_OPERATOR).register(
      'Voting Chain Keeper',
      VOTING_CHAIN_ROBOT,
      5000000,
      LINK_AMOUNT_ROBOT_VOTING_CHAIN.toUint96()
    );

    // FUND ROOTS CONSUMER
    IERC20(ERC677_LINK).transfer(
      ROOTS_CONSUMER,
      IERC20(ERC677_LINK).balanceOf(address(this))
    );
  }
}
