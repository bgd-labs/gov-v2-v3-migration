// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM, AaveV2EthereumAMMAssets} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';
import {ITransparentUpgradeableProxy} from '../../src/contracts/dependencies/ITransparentUpgradeableProxy.sol';
import {IExecutor as IExecutorV2} from '../../src/contracts/dependencies/IExecutor.sol';
import {IStakedToken} from '../../src/contracts/dependencies/IStakedToken.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Mediator} from '../../src/contracts/governance3/Mediator.sol';
import {EthShortMovePermissionsPayload} from '../../src/contracts/governance2.5/EthShortMovePermissionsPayload.sol';
import {EthLongV3Payload} from '../../src/contracts/governance3/EthLongV3Payload.sol';
import {EthShortV3Payload} from '../../src/contracts/governance3/EthShortV3Payload.sol';
import {ShortPayload} from '../mocks/ShortPayload.sol';
import {LongPayload} from '../mocks/LongPayload.sol';

contract EthShortV3PayloadTest is ProtocolV3TestBase {
  //TODO: update addresses
  address public constant A_AAVE_IMPL = 0x6acCc155626E0CF8bFe97e68A17a567394D51238;
  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x27FADCFf20d7A97D3AdBB3a6856CB6DedF2d2132;

  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  EthShortV3Payload public payload;

  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18412862);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPayload() public {
    Mediator mediator = new Mediator();

    EthShortMovePermissionsPayload shortPayload = new EthShortMovePermissionsPayload();
    EthLongV3Payload longPayload = new EthLongV3Payload(address(mediator));

    payload = new EthShortV3Payload(address(mediator));

    // execute 2.5 payload
    GovHelpers.executePayload(vm, address(shortPayload), AaveGovernanceV2.SHORT_EXECUTOR);
    GovHelpers.executePayload(vm, address(longPayload), AaveGovernanceV2.LONG_EXECUTOR);
    GovHelpers.executePayload(vm, address(payload), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.startPrank(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG);

    assertEq(
      ITransparentUpgradeableProxy(address(GovernanceV3Ethereum.GOVERNANCE)).admin(),
      AaveMisc.PROXY_ADMIN_ETHEREUM_LONG
    );

    vm.stopPrank();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    _testExecutor();

    _testRobot();

    vm.stopPrank();

    _testAaveTokenUpgrade();
    _testStkAaveTokenUpgrade();
    _testLongPermissions(address(mediator));
  }

  function _testExecutor() internal {
    assertEq(
      IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).getAdmin(),
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );

    ShortPayload shortPayload = new ShortPayload();

    uint256 executionTime = block.timestamp + 86400;

    IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR).queueTransaction(
      address(shortPayload),
      0,
      'execute()',
      bytes(''),
      executionTime,
      true
    );

    skip(86400);

    IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR).executeTransaction(
      address(shortPayload),
      0,
      'execute()',
      bytes(''),
      executionTime,
      true
    );

    assertEq(IStakedToken(STK_AAVE_IMPL).ghoDebtToken(), shortPayload.GHO_DEBT_TOKEN());

    rewind(86400);
  }

  function _testAAaveUpgrade() internal {
    address newImpl = ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
      vm,
      AaveV3EthereumAssets.AAVE_A_TOKEN
    );

    assertEq(newImpl, A_AAVE_IMPL);

    ReserveConfig[] memory allConfigs = _getReservesConfigs(AaveV3Ethereum.POOL);

    e2eTestAsset(
      AaveV3Ethereum.POOL,
      _findReserveConfig(allConfigs, AaveV3EthereumAssets.USDC_UNDERLYING),
      _findReserveConfig(allConfigs, AaveV3EthereumAssets.AAVE_UNDERLYING)
    );
  }

  function _testLongPermissions(address mediator) internal {
    assertEq(
      IOwnable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).owner(),
      GovernanceV3Ethereum.EXECUTOR_LVL_2
    );

    assertEq(
      IExecutorV2(AaveGovernanceV2.LONG_EXECUTOR).getAdmin(),
      GovernanceV3Ethereum.EXECUTOR_LVL_2
    );

    assertEq(
      IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).owner(),
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );

    LongPayload longPayload = new LongPayload();

    uint256 executionTime = block.timestamp + 604800;

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_2);

    IExecutorWithTimelock(AaveGovernanceV2.LONG_EXECUTOR).queueTransaction(
      address(longPayload),
      0,
      'execute(address)',
      abi.encode(mediator),
      executionTime,
      true
    );

    skip(604800);

    IExecutorWithTimelock(AaveGovernanceV2.LONG_EXECUTOR).executeTransaction(
      address(longPayload),
      0,
      'execute(address)',
      abi.encode(mediator),
      executionTime,
      true
    );

    rewind(604800);

    vm.stopPrank();
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
      AaveSafetyModule.STK_AAVE
    );

    assertEq(newImpl, STK_AAVE_IMPL);
  }

  function _testRobot() internal {
    uint256 govChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(blockhash(block.number - 1), KEEPER_REGISTRY, uint32(registryState.nonce + 1))
      )
    );
    uint256 votingChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          KEEPER_REGISTRY,
          uint32(registryState.nonce + 2)
        )
      )
    );

    (address govChainKeeperTarget, , , , , , , ) = IKeeperRegistry(KEEPER_REGISTRY).getUpkeep(
      govChainKeeperId
    );
    (address votingChainKeeperTarget, , , , , , , ) = IKeeperRegistry(KEEPER_REGISTRY).getUpkeep(
      votingChainKeeperId
    );

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    assertEq(govChainKeeperTarget, payload.GOV_CHAIN_ROBOT());
    assertEq(votingChainKeeperTarget, payload.VOTING_CHAIN_ROBOT());

    assertApproxEqAbs(
      IERC20(AaveV2EthereumAssets.LINK_UNDERLYING).balanceOf(payload.ROOTS_CONSUMER()),
      payload.LINK_AMOUNT_ROOTS_CONSUMER(),
      10
    );
  }
}
