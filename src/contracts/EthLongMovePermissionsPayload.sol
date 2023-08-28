// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {AaveTokenV3} from 'aave-token-v3/AaveTokenV3.sol';
import {StakedAaveV3} from 'aave-stk-gov-v3/contracts/StakedAaveV3.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';

contract EthLongMovePermissionsPayload {
  address public immutable LEVEL_2_EXECUTOR_V3;
  address public immutable AAVE_IMPL;
  address public immutable STK_AAVE_IMPL;

  address public constant PAYLOAD_CONTROLLER = address(1);

  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  constructor(address newExecutor, address aaveTokenImplementation, address stkAaveImplementation) {
    LEVEL_2_EXECUTOR_V3 = newExecutor;
    AAVE_IMPL = aaveTokenImplementation;
    STK_AAVE_IMPL = stkAaveImplementation;
  }

  function execute() external {
    // TOKENS

    // update Aave token impl
    TransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).upgradeToAndCall(
      AAVE_IMPL,
      abi.encodeWithSelector(AaveTokenV3.initialize.selector)
    );

    // move aave token proxy admin owner from Long Executor to ProxyAdminLong
    TransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).changeAdmin(
      AaveMisc.PROXY_ADMIN_ETHEREUM_LONG
    );

    // update stkAave implementation
    ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).upgradeAndCall(
      TransparentUpgradeableProxy(payable(STK_AAVE)),
      address(STK_AAVE_IMPL),
      abi.encodeWithSelector(StakedAaveV3.initialize.selector)
    );

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
