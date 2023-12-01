// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {GovV3Helpers} from 'aave-helpers/GovV3Helpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM, AaveV2EthereumAMMAssets} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';
import {ITransparentUpgradeableProxy} from '../../src/contracts/dependencies/ITransparentUpgradeableProxy.sol';
import {IProxyAdmin} from '../../src/contracts/dependencies/IProxyAdmin.sol';
import {IExecutor as IExecutorV2} from '../../src/contracts/dependencies/IExecutor.sol';
import {IStakedToken} from '../../src/contracts/dependencies/IStakedToken.sol';
import {IKeeperRegistry} from '../../src/contracts/dependencies/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {DeployV3Payload} from '../../scripts/DeployV3Payloads.s.sol';
import {Mediator} from '../../src/contracts/governance3/Mediator.sol';
import {EthLongV3Payload} from '../../src/contracts/governance3/EthLongV3Payload.sol';
import {EthShortV2Payload, IAaveArcTimelock} from '../../src/contracts/governance3/EthShortV2Payload.sol';
import {EthShortV3Payload} from '../../src/contracts/governance3/EthShortV3Payload.sol';
import {ShortPayload} from '../mocks/ShortPayload.sol';
import {LongPayload} from '../mocks/LongPayload.sol';
import {IGovernance} from 'aave-governance-v3/interfaces/IGovernance.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/interfaces/IWithGuardian.sol';

contract EthShortPayloadTest is ProtocolV3TestBase, DeployV3Payload {
  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x0A5a19f1c4a527773F8B6e7428255DD83b7A687b;
  address public constant A_AAVE_IMPL = 0x366AE337897223AEa70e3EBe1862219386f20593;

  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  EthShortV3Payload public payload;

  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18562187);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();

    // unpause pool ethereum v2
    hoax(MiscEthereum.PROTOCOL_GUARDIAN);
    AaveV2Ethereum.POOL_CONFIGURATOR.setPoolPause(false);
  }

  function testPayload() public {
    Mediator mediator = new Mediator();

    EthLongV3Payload longPayload = new EthLongV3Payload(address(mediator));
    payload = new EthShortV3Payload(address(mediator));
    uint40 payloadId = _registerPayload(GovernanceV3Ethereum.PAYLOADS_CONTROLLER, address(payload));

    EthShortV2Payload shortV2Payload = new EthShortV2Payload(payloadId, 1, 1);

    // execute v2 short payload
    GovHelpers.executePayload(vm, address(shortV2Payload), AaveGovernanceV2.SHORT_EXECUTOR);

    // execute v3 long payload
    GovHelpers.executePayload(vm, address(longPayload), AaveGovernanceV2.LONG_EXECUTOR);

    // execute v3 short payload via registered id
    GovV3Helpers.executePayload(vm, payloadId);

    _testGovernanceUpdate();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    _testArc();

    _testEcosystemReserve();

    _testExecutor();

    _testRobot();

    vm.stopPrank();

    _testAaveTokenUpgrade();
    _testStkAaveTokenUpgrade();
    _testLongPermissions(address(mediator));
  }

  function _testGovernanceUpdate() internal {
    hoax(MiscEthereum.PROXY_ADMIN_LONG);
    assertEq(
      ITransparentUpgradeableProxy(address(GovernanceV3Ethereum.GOVERNANCE)).admin(),
      MiscEthereum.PROXY_ADMIN_LONG
    );

    assertEq(IGovernance(address(GovernanceV3Ethereum.GOVERNANCE)).getGasLimit(), 300_000);
    assertEq(
      IOwnable(address(GovernanceV3Ethereum.GOVERNANCE)).owner(),
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );
    assertEq(
      IWithGuardian(address(GovernanceV3Ethereum.GOVERNANCE)).guardian(),
      MiscEthereum.PROTOCOL_GUARDIAN
    );
  }

  function _testArc() internal {
    // execute payload on arc timelock
    uint256 currentActionId = IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).getActionsSetCount();

    skip(3 days + 10);
    IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).execute(currentActionId - 1);

    assertEq(
      IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).getEthereumGovernanceExecutor(),
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );

    rewind(3 days + 10);
  }

  function _testEcosystemReserve() internal {
    MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER.transfer(
      MiscEthereum.ECOSYSTEM_RESERVE,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(this),
      10e18
    );

    IProxyAdmin(MiscEthereum.PROXY_ADMIN).upgrade(
      ITransparentUpgradeableProxy(payable(MiscEthereum.ECOSYSTEM_RESERVE)),
      address(MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER)
    );
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
    assertEq(IOwnable(MiscEthereum.PROXY_ADMIN_LONG).owner(), GovernanceV3Ethereum.EXECUTOR_LVL_2);

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
        abi.encodePacked(blockhash(block.number - 1), KEEPER_REGISTRY, uint32(registryState.nonce))
      )
    );
    uint256 votingChainKeeperId = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          KEEPER_REGISTRY,
          uint32(registryState.nonce + 1)
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
      0.2 ether
    );
  }
}
