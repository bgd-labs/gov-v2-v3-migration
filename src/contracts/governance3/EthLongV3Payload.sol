// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {ITransparentUpgradeableProxy} from '../dependencies/ITransparentUpgradeableProxy.sol';
import {IProxyAdmin} from '../dependencies/IProxyAdmin.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IExecutor as IExecutorV2} from '../dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IMediator} from '../interfaces/IMediator.sol';

/**
 * @title EthLongV3Payload
 * @notice Migrate permissions for stkAave and Aave tokens from Long executor to the mediator contract,
 * @notice upgrade governance v3 implementation.
 * @author BGD Labs
 **/
contract EthLongV3Payload {
  address public immutable MEDIATOR;

  // TODO: update with the new governance address
  address public constant GOVERNANCE_3_IMPL = 0x8543A1c3f8D4Cb0D7363047bec613b6b54740B1d;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // GOVERNANCE V3
    // IProxyAdmin(MiscEthereum.PROXY_ADMIN_ETHEREUM_LONG).upgradeAndCall(
    //   ITransparentUpgradeableProxy(address(GovernanceV3Ethereum.GOVERNANCE)),
    //   GOVERNANCE_3_IMPL,
    //   abi.encodeWithSignature('initialize()')
    // );

    // move aave token proxy admin owner from Long Executor to ProxyAdminLong
    ITransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).changeAdmin(
      MiscEthereum.PROXY_ADMIN_ETHEREUM_LONG
    );

    // proxy admin
    IOwnable(MiscEthereum.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(address(MEDIATOR));

    // set the new executor as the pending admin
    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_2));

    // new executor - change owner to the mediator contract
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(address(MEDIATOR));

    // set the overdue date for the migration
    IMediator(MEDIATOR).setOverdueDate();
  }
}
