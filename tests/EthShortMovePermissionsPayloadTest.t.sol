// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MovePermissionsTestBase} from './MovePermissionsTestBase.sol';
import {ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {Executor} from 'aave-governance-v3/contracts/payloads/Executor.sol';
import {IExecutor as IExecutorV2} from '../src/contracts/dependencies/IExecutor.sol';
import {ILendingPoolAddressProviderV1} from '../src/contracts/dependencies/ILendingPoolAddressProviderV1.sol';
import {IStakedToken} from '../src/contracts/dependencies/IStakedToken.sol';
import {IGhoAccessControl} from '../src/contracts/dependencies/IGhoAccessControl.sol';
import {IPriceProviderV1} from './helpers/IPriceProviderV1.sol';
import {ILendingPoolConfiguratorV1} from './helpers/ILendingPoolConfiguratorV1.sol';
import {EthShortMovePermissionsPayload} from '../src/contracts/EthShortMovePermissionsPayload.sol';

contract EthShortMovePermissionsPayloadTest is MovePermissionsTestBase {
  address public constant A_AAVE_IMPL = 0xC383AAc4B3dC18D9ce08AB7F63B4632716F1e626;

  address public constant AAVE_V1_CONFIGURATOR = 0x4965f6FA20fE9728deCf5165016fc338a5a85aBF;

  address public constant STK_AAVE_ADDRESS = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
  address public constant STK_ABPT_ADDRESS = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 18035350);
  }

  function testPayload() public {
    vm.startPrank(GovernanceV3Ethereum.PAYLOADS_CONTROLLER);
    Ownable(GovernanceV3Ethereum.EXECUTOR_LVL_1).transferOwnership(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.stopPrank();

    EthShortMovePermissionsPayload payload = new EthShortMovePermissionsPayload();

    GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.SHORT_EXECUTOR);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    _testV1(payload.AAVE_V1_ADDRESS_PROVIDER(), payload.AAVE_V1_PRICE_PROVIDER());

    _testV2(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV2EthereumAssets.WBTC_UNDERLYING,
      AaveV2EthereumAssets.WBTC_ORACLE,
      AaveV2Ethereum.WETH_GATEWAY
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
      AaveMisc.PROXY_ADMIN_ETHEREUM,
      AaveV3Ethereum.WETH_GATEWAY,
      AaveV3Ethereum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Ethereum.REPAY_WITH_COLLATERAL_ADAPTER
    );

    vm.startPrank(AaveMisc.PROXY_ADMIN_ETHEREUM);
    _testMisc(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      payload.LEND_TO_AAVE_MIGRATOR(),
      payload.AAVE_MERKLE_DISTRIBUTOR()
    );
    vm.stopPrank();
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    _testExecutor(GovernanceV3Ethereum.EXECUTOR_LVL_1, GovernanceV3Ethereum.PAYLOADS_CONTROLLER);

    _testStkRoles();

    _testCrosschainFunding(
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      AaveV3EthereumAssets.LINK_UNDERLYING,
      payload.ETH_AMOUNT(),
      payload.LINK_AMOUNT()
    );

    _testGhoPermissions();

    vm.stopPrank();
  }

  function _testMisc(
    address newExecutor,
    address lendToAaveMigrator,
    address aaveMerkleDistributor
  ) internal {
    // Lend to Aave migrator
    assertEq(
      TransparentUpgradeableProxy(payable(lendToAaveMigrator)).admin(),
      AaveMisc.PROXY_ADMIN_ETHEREUM
    );

    // Merkle Distributor
    assertEq(Ownable(aaveMerkleDistributor).owner(), newExecutor);
  }

  function _testExecutor(address newExecutor, address payloadController) internal {
    assertEq(IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).getAdmin(), newExecutor);

    assertEq(Ownable(newExecutor).owner(), payloadController);
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
    IStakedToken stkAave = IStakedToken(STK_AAVE_ADDRESS);
    IStakedToken stkABPT = IStakedToken(STK_ABPT_ADDRESS);

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
}
