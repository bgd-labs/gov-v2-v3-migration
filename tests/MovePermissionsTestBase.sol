// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProtocolV3TestBase} from 'aave-helpers/ProtocolV3TestBase.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {ILendingPoolAddressesProvider, ILendingPoolConfigurator, IAaveOracle as IAaveOracleV2, ILendingRateOracle} from 'aave-address-book/AaveV2.sol';
import {IPoolAddressesProvider, IPoolConfigurator, IACLManager, IAaveOracle as IAaveOracleV3} from 'aave-address-book/AaveV3.sol';
import {ICollector} from 'aave-address-book/common/ICollector.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {PolygonMovePermissionsPayload} from '../src/contracts/PolygonMovePermissionsPayload.sol';
import {IPoolAddressProviderRegistry} from './helpers/IPoolAddressProviderRegistry.sol';
import {IEmissionManager} from './helpers/IEmissionManager.sol';

contract MovePermissionsTestBase is ProtocolV3TestBase {
  function _testV2(
    address newExecutor,
    ILendingPoolAddressesProvider poolAddressProvider,
    address poolAddressProviderRegistry,
    address asset,
    address assetSource,
    address wethGateway
  ) internal {
    // check Pool Admin
    ILendingPoolConfigurator(poolAddressProvider.getLendingPoolConfigurator()).freezeReserve(asset);

    // check address provider owner
    poolAddressProvider.setPoolAdmin(newExecutor);

    // check oracle owner
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);

    assets[0] = asset;
    sources[0] = assetSource;
    IAaveOracleV2(poolAddressProvider.getPriceOracle()).setAssetSources(assets, sources);

    // check lending rate oracle owner
    ILendingRateOracle(poolAddressProvider.getLendingRateOracle()).setMarketBorrowRate(asset, 33);

    // check LendingPoolAddressesProviderRegistry owner
    IPoolAddressProviderRegistry(poolAddressProviderRegistry).unregisterAddressesProvider(
      address(poolAddressProvider)
    );

    // WETH_GATEWAY
    assertEq(Ownable(wethGateway).owner(), newExecutor);
  }

  function _testV3(
    address newExecutor,
    IPoolAddressesProvider poolAddressProvider,
    ICollector collector,
    address asset,
    address aAsset,
    address assetSource,
    address emissionManager,
    address poolAddressProviderRegistry,
    address proxyAdmin,
    address wethGateway,
    address swapCollateral,
    address repayWithCollateral
  ) internal {
    // check Pool Admin
    IPoolConfigurator(poolAddressProvider.getPoolConfigurator()).setReserveFreeze(asset, true);

    // ACLManager - default admin role
    IACLManager aclManager = IACLManager(poolAddressProvider.getACLManager());
    aclManager.setRoleAdmin(aclManager.RISK_ADMIN_ROLE(), aclManager.DEFAULT_ADMIN_ROLE());

    // check pool address provider owner
    poolAddressProvider.setMarketId('3');

    // check oracle permissions
    _checkOraclePermissions(poolAddressProvider.getPriceOracle(), asset, assetSource);

    // Emission Manager
    IEmissionManager(emissionManager).setRewardsController(address(1));

    // check LendingPoolAddressesProviderRegistry owner
    IPoolAddressProviderRegistry(poolAddressProviderRegistry).unregisterAddressesProvider(
      address(poolAddressProvider)
    );

    // Collector
    collector.approve(aAsset, address(1), 100);

    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
      address(collector),
      proxyAdmin,
      ''
    );

    // Proxy Admin
    ProxyAdmin(proxyAdmin).changeProxyAdmin(proxy, address(this));

    // WETH_GATEWAY
    if (wethGateway != address(0)) {
      assertEq(Ownable(wethGateway).owner(), newExecutor);
    }

    // ParaSwapLiquiditySwapAdapter
    if (swapCollateral != address(0)) {
      assertEq(Ownable(swapCollateral).owner(), newExecutor);
    }

    // ParaSwapRepayAdapter
    if (repayWithCollateral != address(0)) {
      assertEq(Ownable(repayWithCollateral).owner(), newExecutor);
    }
  }

  function _checkOraclePermissions(address oracle, address asset, address assetSource) internal {
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);

    assets[0] = asset;
    sources[0] = assetSource;
    IAaveOracleV3(oracle).setAssetSources(assets, sources);
  }

  function _testCrosschainFunding(
    address crosschainController,
    address linkAddress,
    uint256 nativeAmount,
    uint256 linkAmount
  ) internal {
    uint256 nativeAfter = address(crosschainController).balance;
    uint256 linkAfter = IERC20(linkAddress).balanceOf(crosschainController);

    assertTrue(nativeAfter >= nativeAmount);
    assertTrue(linkAfter >= linkAmount);
  }
}
