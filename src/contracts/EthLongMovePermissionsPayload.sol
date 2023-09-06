// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';

contract EthLongMovePermissionsPayload {
  function execute() external {
    Ownable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(
      address(GovernanceV3Ethereum.EXECUTOR_LVL_2)
    );

    // EXECUTOR PERMISSIONS

    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_2));

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_2).executeTransaction(
      address(this),
      0,
      'acceptAdmin()',
      bytes(''),
      false
    );

    // new executor - change owner to payload controller
    Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(
      GovernanceV3Ethereum.PAYLOADS_CONTROLLER
    );
  }
}
