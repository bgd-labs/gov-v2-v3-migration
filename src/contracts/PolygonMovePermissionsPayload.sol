// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';

import {MigratorLib} from './MigratorLib.sol';

contract PolygonMovePermissionsPayload {
  // ~ 20 proposals
  uint256 public constant MATIC_AMOUNT = 2040 ether;
  uint256 public constant LINK_AMOUNT = 114 ether;

  address public constant GELATO_ADDRESS = 0x73495115E38A307DA3419Bf062bb050b96f68Cf3;
  uint256 public constant GELATO_AMOUNT = 10_000e6;

  function execute() external {
    // GELATO FUNDING
    AaveV3Polygon.COLLECTOR.transfer(
      AaveV3PolygonAssets.USDC_A_TOKEN,
      address(this),
      GELATO_AMOUNT
    );

    AaveV3Polygon.POOL.withdraw(AaveV3PolygonAssets.USDC_UNDERLYING, GELATO_AMOUNT, GELATO_ADDRESS);

    // CC FUNDING
    MigratorLib.fundCrosschainController(
      AaveV3Polygon.COLLECTOR,
      AaveV3Polygon.POOL,
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      AaveV3PolygonAssets.WMATIC_A_TOKEN,
      MATIC_AMOUNT,
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3PolygonAssets.LINK_UNDERLYING,
      AaveV3PolygonAssets.LINK_A_TOKEN,
      LINK_AMOUNT,
      true
    );

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV2Polygon.ORACLE,
      AaveV2Polygon.LENDING_RATE_ORACLE,
      AaveV2Polygon.WETH_GATEWAY,
      AaveV2Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY
    );

    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      AaveV3Polygon.ACL_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV3Polygon.EMISSION_MANAGER,
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Polygon.COLLECTOR,
      AaveMisc.PROXY_ADMIN_POLYGON,
      AaveV3Polygon.WETH_GATEWAY,
      AaveV3Polygon.SWAP_COLLATERAL_ADAPTER,
      AaveV3Polygon.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Polygon.WITHDRAW_SWAP_ADAPTER
    );
  }
}
