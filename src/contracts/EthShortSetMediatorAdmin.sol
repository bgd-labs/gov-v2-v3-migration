// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IMediator} from './interfaces/IMediator.sol';

contract EthShortSetMediatorAdmin {
  address public constant MEDIATOR = address(0);

  function execute() external {
    IExecutorV2(address(this)).setPendingAdmin(address(MEDIATOR));

    IMediator(MEDIATOR).acceptShortAdmin();
  }
}
