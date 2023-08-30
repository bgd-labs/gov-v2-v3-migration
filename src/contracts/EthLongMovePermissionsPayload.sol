// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';

contract EthLongMovePermissionsPayload {
  address public immutable LEVEL_2_EXECUTOR_V3;

  address public constant PAYLOAD_CONTROLLER = address(1);

  constructor(address newExecutor) {
    LEVEL_2_EXECUTOR_V3 = newExecutor;
  }

  function execute() external {
    Ownable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(address(LEVEL_2_EXECUTOR_V3));

    // EXECUTOR PERMISSIONS

    IExecutorV2(address(this)).setPendingAdmin(address(LEVEL_2_EXECUTOR_V3));

    // new executor - call execute payload to accept new permissions
    IExecutorV3(LEVEL_2_EXECUTOR_V3).executeTransaction(
      address(this),
      0,
      'acceptAdmin()',
      bytes(''),
      false
    );

    // new executor - change owner to payload controller
    Ownable(LEVEL_2_EXECUTOR_V3).transferOwnership(PAYLOAD_CONTROLLER);
  }
}
