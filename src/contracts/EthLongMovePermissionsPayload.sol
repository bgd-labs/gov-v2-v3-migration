// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IMediator} from './interfaces/IMediator.sol';

contract EthLongMovePermissionsPayload {
  address public immutable MEDIATOR;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // move aave token proxy admin owner from Long Executor to ProxyAdminLong
    TransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).changeAdmin(
      AaveMisc.PROXY_ADMIN_ETHEREUM_LONG
    );

    // proxy admin
    IOwnable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(address(MEDIATOR));

    // set new executor as th pending admin
    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_2));

    // new executor - change owner to the mediator contract
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(address(MEDIATOR));

    // set overdue date for the migration
    IMediator(MEDIATOR).setOverdueDate();
  }
}
