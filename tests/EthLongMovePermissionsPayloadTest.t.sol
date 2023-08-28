// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveTokenV3} from 'aave-token-v3/AaveTokenV3.sol';
import {StakedAaveV3} from 'aave-stk-gov-v3/contracts/StakedAaveV3.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {Executor} from 'aave-governance-v3/contracts/payloads/Executor.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';

contract EthLongMovePermissionsPayloadTest is Test {
  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 17969348);
  }

  function testPayload() public {
    Executor newExecutor = new Executor();
    Ownable(newExecutor).transferOwnership(AaveGovernanceV2.LONG_EXECUTOR);

    AaveTokenV3 aaveToken = new AaveTokenV3();

    StakedAaveV3 stkAaveImpl = new StakedAaveV3(
      IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
      IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING),
      172800,
      AaveMisc.ECOSYSTEM_RESERVE,
      AaveGovernanceV2.SHORT_EXECUTOR, // should be v3
      3155692601
    );

    EthLongMovePermissionsPayload payload = new EthLongMovePermissionsPayload(
      address(newExecutor),
      address(aaveToken),
      address(stkAaveImpl)
    );

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.LONG_EXECUTOR);

    vm.startPrank(payload.LEVEL_2_EXECUTOR_V3());

    assertEq(IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getAdmin(), payload.LEVEL_2_EXECUTOR_V3());

    assertEq(Ownable(payload.LEVEL_2_EXECUTOR_V3()).owner(), payload.PAYLOAD_CONTROLLER());

    // test tokens could be redeployed

    // update Aave token impl
    ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).upgrade(
      TransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)),
      address(aaveToken)
    );

    // update stkAave implementation
    ProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).upgrade(
      TransparentUpgradeableProxy(payable(STK_AAVE)),
      address(stkAaveImpl)
    );

    vm.stopPrank();
  }
}
