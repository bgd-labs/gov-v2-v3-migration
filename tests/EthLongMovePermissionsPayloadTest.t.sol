// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {Executor} from 'aave-governance-v3/contracts/payloads/Executor.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';

contract EthLongMovePermissionsPayloadTest is ProtocolV3TestBase {
  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 18113580);
  }

  function testPayload() public {
    vm.startPrank(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER));
    Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(AaveGovernanceV2.LONG_EXECUTOR);
    vm.stopPrank();

    EthLongMovePermissionsPayload payload = new EthLongMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.LONG_EXECUTOR);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_2);

    assertEq(
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getAdmin(),
      GovernanceV3Ethereum.EXECUTOR_LVL_2
    );

    assertEq(
      Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_2).owner(),
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );

    vm.stopPrank();

    _testAaveTokenUpgrade();
    _testStkAaveTokenUpgrade();
  }

  function _testAaveTokenUpgrade() internal {
    address newImpl = ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
      vm,
      AaveV3EthereumAssets.AAVE_UNDERLYING
    );

    assertEq(newImpl, 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322);

    ReserveConfig[] memory allConfigs = _getReservesConfigs(AaveV3Ethereum.POOL);

    e2eTestAsset(
      AaveV3Ethereum.POOL,
      _findReserveConfig(allConfigs, AaveV3EthereumAssets.USDC_UNDERLYING),
      _findReserveConfig(allConfigs, AaveV3EthereumAssets.AAVE_UNDERLYING)
    );
  }

  function _testStkAaveTokenUpgrade() internal {
    address newImpl = ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
      vm,
      STK_AAVE
    );

    assertEq(newImpl, STK_AAVE_IMPL);
  }
}
