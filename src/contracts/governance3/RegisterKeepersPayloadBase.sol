// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';

/**
 * @title RegisterKeepersPayloadBase
 * @notice Register keepers for governance v3.
 * @author BGD Labs
 **/
contract RegisterKeepersPayloadBase {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  function _registerKeepers(
    address linkAddress,
    uint256 linkAmountVotingChain,
    address robotOperator,
    address votingChainRobot,
    address rootsConsumer
  ) internal {
    // REGISTER NEW VOTING CHAIN KEEPER
    IERC20(linkAddress).forceApprove(robotOperator, linkAmountVotingChain);

    IAaveCLRobotOperator(robotOperator).register(
      'Voting Chain Keeper',
      votingChainRobot,
      5000000,
      linkAmountVotingChain.toUint96()
    );

    // FUND ROOTS CONSUMER
    IERC20(linkAddress).transfer(rootsConsumer, IERC20(linkAddress).balanceOf(address(this)));
  }
}
