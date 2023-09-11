// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {ILendingPoolAddressesProvider, IAaveOracle, ILendingRateOracle} from 'aave-address-book/AaveV2.sol';
import {IACLManager, IPoolAddressesProvider, IPool} from 'aave-address-book/AaveV3.sol';
import {ICollector} from 'aave-address-book/common/ICollector.sol';
import {IWrappedTokenGateway} from './dependencies/IWrappedTokenGateway.sol';

library MigratorLib {
  function migrateV2PoolPermissions(
    address executor,
    ILendingPoolAddressesProvider poolAddressesProvider,
    IAaveOracle oracle, // per chain
    ILendingRateOracle lendingRateOracle, // per chain
    address wETHGateway,
    address poolAddressesProviderRegistry
  ) internal {
    poolAddressesProvider.setPoolAdmin(executor);
    Ownable(address(poolAddressesProvider)).transferOwnership(executor);
    Ownable(wETHGateway).transferOwnership(executor);

    // this components are common across different pools, and maybe already transfered
    if (Ownable(address(oracle)).owner() == address(this)) {
      Ownable(address(oracle)).transferOwnership(executor);
    }
    if (Ownable(address(lendingRateOracle)).owner() == address(this)) {
      Ownable(address(lendingRateOracle)).transferOwnership(executor);
    }
    if (Ownable(address(poolAddressesProviderRegistry)).owner() == address(this)) {
      Ownable(poolAddressesProviderRegistry).transferOwnership(executor);
    }
  }

  function migrateV3PoolPermissions(
    address executor,
    IACLManager aclManager,
    IPoolAddressesProvider poolAddressesProvider,
    address emissionManager,
    address poolAddressesProviderRegistry,
    ICollector collector,
    address proxyAdmin,
    address wETHGateway,
    address swapCollateralAdapter,
    address repayWithCollateralAdapter
  ) internal {
    // grant pool admin role
    aclManager.grantRole(aclManager.POOL_ADMIN_ROLE(), executor);
    aclManager.renounceRole(aclManager.POOL_ADMIN_ROLE(), address(this));

    // grant default admin role
    aclManager.grantRole(aclManager.DEFAULT_ADMIN_ROLE(), executor);
    aclManager.renounceRole(aclManager.DEFAULT_ADMIN_ROLE(), address(this));

    poolAddressesProvider.setACLAdmin(executor);

    // transfer pool address provider ownership
    Ownable(address(poolAddressesProvider)).transferOwnership(executor);

    Ownable(emissionManager).transferOwnership(executor);

    Ownable(poolAddressesProviderRegistry).transferOwnership(executor);

    collector.setFundsAdmin(executor);

    Ownable(proxyAdmin).transferOwnership(executor);

    // Optional components
    if (wETHGateway != address(0)) {
      Ownable(wETHGateway).transferOwnership(executor);
    }

    if (swapCollateralAdapter != address(0)) {
      Ownable(swapCollateralAdapter).transferOwnership(executor);
    }

    if (repayWithCollateralAdapter != address(0)) {
      Ownable(repayWithCollateralAdapter).transferOwnership(executor);
    }
  }

  function fundCrosschainController(
    ICollector collector,
    IPool pool,
    address crosschainController,
    address nativeAToken,
    uint256 nativeAmount,
    address wethGateway,
    address linkToken,
    address linkAToken,
    uint256 linkAmount,
    bool withdrawALink
  ) internal {
    // transfer native a token
    collector.transfer(nativeAToken, address(this), nativeAmount);

    IERC20(nativeAToken).approve(wethGateway, nativeAmount);

    // withdraw native
    IWrappedTokenGateway(wethGateway).withdrawETH(
      address(this),
      nativeAmount,
      crosschainController
    );

    if (withdrawALink) {
      // transfer aLink token from the treasury to the current address
      collector.transfer(linkAToken, address(this), linkAmount);

      // withdraw aLINK from the aave pool and receive LINK
      pool.withdraw(linkToken, linkAmount, address(this));

      // transfer LINK to the CC
      IERC20(linkToken).transfer(crosschainController, IERC20(linkToken).balanceOf(address(this)));
    } else {
      // transfer Link to CC
      collector.transfer(linkToken, crosschainController, linkAmount);
    }
  }
}
