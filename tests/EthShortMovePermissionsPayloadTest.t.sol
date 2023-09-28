// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {ITransparentUpgradeableProxy} from '../src/contracts/dependencies/ITransparentUpgradeableProxy.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM, AaveV2EthereumAMMAssets} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {ILendingPoolAddressProviderV1} from '../src/contracts/dependencies/ILendingPoolAddressProviderV1.sol';
import {IStakedToken} from '../src/contracts/dependencies/IStakedToken.sol';
import {IGhoAccessControl} from '../src/contracts/dependencies/IGhoAccessControl.sol';
import {IPriceProviderV1} from './helpers/IPriceProviderV1.sol';
import {ILendingPoolConfiguratorV1} from './helpers/ILendingPoolConfiguratorV1.sol';
import {IKeeperRegistry} from '../src/contracts/dependencies/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Mediator} from '../src/contracts/Mediator.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';
import {EthShortMovePermissionsPayload} from '../src/contracts/EthShortMovePermissionsPayload.sol';

contract EthShortMovePermissionsPayloadTest is MovePermissionsTestBase {
  address public constant A_AAVE_IMPL = 0x6acCc155626E0CF8bFe97e68A17a567394D51238;

  address public constant AAVE_V1_CONFIGURATOR = 0x4965f6FA20fE9728deCf5165016fc338a5a85aBF;

  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x27FADCFf20d7A97D3AdBB3a6856CB6DedF2d2132;

  address public KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

  EthShortMovePermissionsPayload public payload;

  IKeeperRegistry.State public registryState;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18230033);
    (registryState, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
  }

  function testPayload() public {
    Mediator mediator = new Mediator();

    EthLongMovePermissionsPayload longPayload = new EthLongMovePermissionsPayload(
      address(mediator)
    );

    payload = new EthShortMovePermissionsPayload(address(mediator));

    GovHelpers.executePayload(vm, address(longPayload), AaveGovernanceV2.LONG_EXECUTOR);

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.SHORT_EXECUTOR);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    _testV1(payload.AAVE_V1_ADDRESS_PROVIDER(), payload.AAVE_V1_PRICE_PROVIDER());

    _testV2(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2EthereumAssets.WBTC_UNDERLYING,
      AaveV2EthereumAssets.WBTC_ORACLE,
      AaveV2Ethereum.WETH_GATEWAY,
      address(0),
      address(0),
      AaveV2Ethereum.DEBT_SWAP_ADAPTER
    );

    _testV2(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2EthereumAMMAssets.WBTC_UNDERLYING,
      AaveV2EthereumAMMAssets.WBTC_ORACLE,
      AaveV2EthereumAMM.WETH_GATEWAY,
      address(0),
      address(0),
      address(0)
    );

    _testV3(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV3Ethereum.COLLECTOR,
      AaveV3EthereumAssets.DAI_UNDERLYING,
      AaveV3EthereumAssets.DAI_A_TOKEN,
      AaveV3EthereumAssets.DAI_ORACLE,
      AaveV3Ethereum.EMISSION_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveMisc.PROXY_ADMIN_ETHEREUM
    );

    _testV3Optional(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV3Ethereum.WETH_GATEWAY,
      AaveV3Ethereum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Ethereum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Ethereum.WITHDRAW_SWAP_ADAPTER,
      AaveV3Ethereum.DEBT_SWAP_ADAPTER
    );

    _testMisc(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      payload.LEND_TO_AAVE_MIGRATOR(),
      payload.AAVE_MERKLE_DISTRIBUTOR()
    );

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    _testExecutor(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );

    _testStkRoles();

    _testCrosschainFunding(
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      AaveV3EthereumAssets.LINK_UNDERLYING,
      payload.ETH_AMOUNT_CROSSCHAIN_CONTROLLER(),
      payload.LINK_AMOUNT_CROSSCHAIN_CONTROLLER()
    );

    _testRobot();

    _testGhoPermissions();

    vm.stopPrank();

    _testLongPermissions();
    _testAaveTokenUpgrade();
    _testStkAaveTokenUpgrade();
  }

  function _testMisc(
    address newExecutor,
    address lendToAaveMigrator,
    address aaveMerkleDistributor
  ) internal {
    vm.startPrank(AaveMisc.PROXY_ADMIN_ETHEREUM);

    // Lend to Aave migrator
    assertEq(
      ITransparentUpgradeableProxy(lendToAaveMigrator).admin(),
      AaveMisc.PROXY_ADMIN_ETHEREUM
    );

    vm.stopPrank();

    // Merkle Distributor
    assertEq(IOwnable(aaveMerkleDistributor).owner(), newExecutor);

    assertEq(IOwnable(AaveMisc.AAVE_SWAPPER_ETHEREUM).owner(), newExecutor);
    assertEq(IOwnable(AaveMisc.AAVE_POL_ETH_BRIDGE).owner(), newExecutor);
  }

  function _testExecutor(address newExecutor, address payloadController) internal {
    assertEq(IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).getAdmin(), newExecutor);

    assertEq(IOwnable(newExecutor).owner(), payloadController);
  }

  function _testV1(address addressProvider, address priceProvider) internal {
    // freeze reserve
    ILendingPoolConfiguratorV1(AAVE_V1_CONFIGURATOR).freezeReserve(
      0x6B175474E89094C44Da98b954EedeAC495271d0F // DAI
    );

    // set price oracle
    ILendingPoolAddressProviderV1(addressProvider).setPriceOracle(address(33));

    // check price provider
    IPriceProviderV1(priceProvider).setFallbackOracle(address(12));
  }

  function _testStkRoles() internal {
    // stk tokens - set admin roles
    IStakedToken stkAave = IStakedToken(AaveSafetyModule.STK_AAVE);
    IStakedToken stkABPT = IStakedToken(AaveSafetyModule.STK_ABPT);

    stkAave.setPendingAdmin(stkAave.SLASH_ADMIN_ROLE(), address(1));
    stkAave.setPendingAdmin(stkAave.COOLDOWN_ADMIN_ROLE(), address(2));
    stkAave.setPendingAdmin(stkAave.CLAIM_HELPER_ROLE(), address(3));

    stkABPT.setPendingAdmin(stkABPT.SLASH_ADMIN_ROLE(), address(1));
    stkABPT.setPendingAdmin(stkABPT.COOLDOWN_ADMIN_ROLE(), address(2));
    stkABPT.setPendingAdmin(stkABPT.CLAIM_HELPER_ROLE(), address(3));
  }

  function _testGhoPermissions() internal {
    IGhoAccessControl ghoToken = IGhoAccessControl(AaveV3Ethereum.GHO_TOKEN);

    ghoToken.addFacilitator(address(1), 'test_one', 1 ether);
    ghoToken.setFacilitatorBucketCapacity(address(1), 2 ether);

    ghoToken.grantRole(ghoToken.FACILITATOR_MANAGER_ROLE(), address(2));

    assertTrue(!ghoToken.hasRole(ghoToken.DEFAULT_ADMIN_ROLE(), AaveGovernanceV2.SHORT_EXECUTOR));
    assertTrue(
      !ghoToken.hasRole(ghoToken.FACILITATOR_MANAGER_ROLE(), AaveGovernanceV2.SHORT_EXECUTOR)
    );
    assertTrue(!ghoToken.hasRole(ghoToken.BUCKET_MANAGER_ROLE(), AaveGovernanceV2.SHORT_EXECUTOR));
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

  function _testLongPermissions() internal {
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
    uint256 executionChainKeeperId = uint256(
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
    (address executionChainKeeperTarget, , , , , , , ) = IKeeperRegistry(KEEPER_REGISTRY).getUpkeep(
      executionChainKeeperId
    );

    assertEq(IOwnable(payload.ROBOT_OPERATOR()).owner(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    assertEq(govChainKeeperTarget, payload.GOV_CHAIN_ROBOT());
    assertEq(votingChainKeeperTarget, payload.VOTING_CHAIN_ROBOT());
    assertEq(executionChainKeeperTarget, payload.EXECUTION_CHAIN_ROBOT());

    assertEq(
      payload.LINK_AMOUNT_ROOTS_CONSUMER(),
      IERC20(AaveV2EthereumAssets.LINK_UNDERLYING).balanceOf(payload.ROOTS_CONSUMER())
    );
  }
}
