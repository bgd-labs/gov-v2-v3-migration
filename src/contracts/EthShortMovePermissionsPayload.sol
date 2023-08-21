// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IBalancerOwnable} from './dependencies/IBalancerOwnable.sol';
import {ILendingPoolAddressProviderV1} from './dependencies/ILendingPoolAddressProviderV1.sol';
import {MigratorLib} from './MigratorLib.sol';

contract EthShortMovePermissionsPayload {
  address public immutable LEVEL_1_EXECUTOR_V3;

  address public constant PAYLOAD_CONTROLLER = address(1);
  address payable public constant LEND_TO_AAVE_MIGRATOR =
    payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);
  address public constant AAVE_MERKLE_DISTRIBUTOR =
    0xa88c6D90eAe942291325f9ae3c66f3563B93FE10;
  address payable public constant ABPT =
    payable(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);

  address public constant AAVE_V1_ADDRESS_PROVIDER =
    0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

  address public constant AAVE_V1_PRICE_PROVIDER =
    0x76B47460d7F7c5222cFb6b6A75615ab10895DDe4;

  constructor(address newExecutor) {
    LEVEL_1_EXECUTOR_V3 = newExecutor;
  }

  function execute() external {
    // V1 MARKET

    // lending pool manager
    ILendingPoolAddressProviderV1(AAVE_V1_ADDRESS_PROVIDER)
      .setLendingPoolManager(LEVEL_1_EXECUTOR_V3);

    // owner of address provider
    Ownable(AAVE_V1_ADDRESS_PROVIDER).transferOwnership(LEVEL_1_EXECUTOR_V3);

    // owner of price provider
    Ownable(AAVE_V1_PRICE_PROVIDER).transferOwnership(LEVEL_1_EXECUTOR_V3);

    // V2 MARKETS
    MigratorLib.migrateV2MarketPermissions(
      LEVEL_1_EXECUTOR_V3,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV2Ethereum.ORACLE,
      AaveV2Ethereum.LENDING_RATE_ORACLE,
      AaveV2Ethereum.WETH_GATEWAY,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY
    );
    MigratorLib.migrateV2MarketPermissions(
      LEVEL_1_EXECUTOR_V3,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER,
      AaveV2EthereumAMM.ORACLE,
      AaveV2EthereumAMM.LENDING_RATE_ORACLE,
      AaveV2EthereumAMM.WETH_GATEWAY,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER_REGISTRY
    );

    // V3 MARKETS
    MigratorLib.migrateV3MarketPermissions(
      LEVEL_1_EXECUTOR_V3,
      AaveV3Ethereum.ACL_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV3Ethereum.EMISSION_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Ethereum.COLLECTOR,
      AaveMisc.PROXY_ADMIN_ETHEREUM,
      AaveV3Ethereum.WETH_GATEWAY,
      AaveV3Ethereum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Ethereum.REPAY_WITH_COLLATERAL_ADAPTER
    );

    // MISC ECOSYSTEM

    // MerkleDistributor
    Ownable(AAVE_MERKLE_DISTRIBUTOR).transferOwnership(LEVEL_1_EXECUTOR_V3);

    // LendToAave Migrator
    TransparentUpgradeableProxy(LEND_TO_AAVE_MIGRATOR).changeAdmin(
      LEVEL_1_EXECUTOR_V3
    );

    // Safety module
    TransparentUpgradeableProxy(ABPT).changeAdmin(LEVEL_1_EXECUTOR_V3);
    IBalancerOwnable(ABPT).setController(LEVEL_1_EXECUTOR_V3);

    // DefaultIncentivesController - do we need it?

    // EXECUTOR PERMISSIONS

    IExecutorV2(address(this)).setPendingAdmin(address(LEVEL_1_EXECUTOR_V3));

    // new executor - call execute payload to accept new permissions
    IExecutorV3(LEVEL_1_EXECUTOR_V3).executeTransaction(
      address(this),
      0,
      'acceptAdmin()',
      bytes(''),
      false
    );

    // new executor - change owner to payload controller
    Ownable(LEVEL_1_EXECUTOR_V3).transferOwnership(PAYLOAD_CONTROLLER);
  }
}
