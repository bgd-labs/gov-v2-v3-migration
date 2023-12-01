// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';

/**
 * @title BaseSwapsPayload
 * @notice Migrate owner of the swap adapters to the new executor
 * @author BGD Labs
 **/
contract BaseSwapsPayload {
  function execute() external {
    IOwnable(AaveV3Base.SWAP_COLLATERAL_ADAPTER).transferOwnership(GovernanceV3Base.EXECUTOR_LVL_1);

    IOwnable(AaveV3Base.REPAY_WITH_COLLATERAL_ADAPTER).transferOwnership(
      GovernanceV3Base.EXECUTOR_LVL_1
    );

    IOwnable(AaveV3Base.WITHDRAW_SWAP_ADAPTER).transferOwnership(GovernanceV3Base.EXECUTOR_LVL_1);
  }
}
