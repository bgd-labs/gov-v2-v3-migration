// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

contract Mediator is IMediator {
  bool private _isCancelled;
  bool private _isExecuted;

  address public constant GUARDIAN = AaveV2Ethereum.EMERGENCY_ADMIN;

  /**
   * @dev Throws if the caller is not the guardian.
   */
  modifier onlyGuardian() {
    if (msg.sender != AaveV2Ethereum.EMERGENCY_ADMIN) {
      revert InvalidCaller();
    }
  }

  function getIsExecuted() external returns (bool) {
    return _isExecuted;
  }

  function getIsCancelled() external returns (bool) {
    return _isCancelled;
  }

  function acceptShortAdmin() external {
    IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).acceptAdmin();
  }

  function acceptLongAdmin() external {
    IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).acceptAdmin();
  }

  function execute() external {
    if (
      IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).getAdmin() != address(this) ||
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getAdmin() != address(this)
    ) {
      revert();
    }

    // queue and execute long proposal

    // queue and execute short proposal

    // give permissions back to governance v2

    // set executed flag
  }

  function cancel() external onlyGuardian {
    if (IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).getAdmin() == address(this)) {}

    if (IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).getAdmin() == address(this)) {}
    // give admin permissions back
  }
}
