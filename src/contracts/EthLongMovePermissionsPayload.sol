// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';

contract EthLongMovePermissionsPayload {
  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;

  function execute() external {
    // UPDATE TOKENS

    // update Aave token impl
    TransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).upgradeToAndCall(
      AAVE_IMPL,
      abi.encodeWithSignature('initialize()')
    );

    // move aave token proxy admin owner from Long Executor to ProxyAdminLong
    TransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).changeAdmin(
      AaveMisc.PROXY_ADMIN_ETHEREUM_LONG
    );

    // upgrade stk aave
    ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).upgradeAndCall(
      TransparentUpgradeableProxy(payable(STK_AAVE)),
      address(STK_AAVE_IMPL),
      abi.encodeWithSignature('initialize()')
    );

    // PROXY ADMIN

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
