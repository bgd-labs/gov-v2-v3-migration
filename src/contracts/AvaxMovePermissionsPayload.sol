// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

/**
 * @title AvaxMovePermissionsPayload
 * @notice Migrate permissions for Aave V2 and V3 Pools on Avalanche from governance v2 to v3
 * and fund cross chain controller
 * @author BGD Labs
 **/
contract AvaxMovePermissionsPayload {
  // ~ 20 proposals
  uint256 public constant AVAX_AMOUNT = 361 ether;
  uint256 public constant LINK_AMOUNT = 250 ether;

  function execute() external {
    // CC FUNDING
    MigratorLib.fundCrosschainControllerNative(
      AaveV3Avalanche.COLLECTOR,
      GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER,
      AaveV3AvalancheAssets.WAVAX_A_TOKEN,
      AVAX_AMOUNT,
      AaveV3Avalanche.WETH_GATEWAY
    );

    _fundCrosschainControllerLink();

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV2Avalanche.ORACLE,
      AaveV2Avalanche.LENDING_RATE_ORACLE,
      AaveV2Avalanche.WETH_GATEWAY,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      address(0), // swap collateral adapter owned by https://snowtrace.io/address/0x05182e579fdfcf69e4390c3411d8fea1fb6467cf
      address(0), // repay with collateral adapter owned by https://snowtrace.io/address/0x05182e579fdfcf69e4390c3411d8fea1fb6467cf
      AaveV2Avalanche.DEBT_SWAP_ADAPTER
    );
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      AaveV3Avalanche.ACL_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV3Avalanche.EMISSION_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Avalanche.COLLECTOR,
      AaveMisc.PROXY_ADMIN_AVALANCHE,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3Avalanche.SWAP_COLLATERAL_ADAPTER,
      AaveV3Avalanche.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Avalanche.WITHDRAW_SWAP_ADAPTER,
      AaveV3Avalanche.DEBT_SWAP_ADAPTER
    );

    // Proof of reserve
    IOwnable(AaveV2Avalanche.PROOF_OF_RESERVE).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );

    IOwnable(AaveV3Avalanche.PROOF_OF_RESERVE).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
    // one per network
    IOwnable(AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR).transferOwnership(
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
  }

  function _fundCrosschainControllerLink() internal {
    // transfer aLink token from the treasury to the current address
    AaveV3Avalanche.COLLECTOR.transfer(
      AaveV3AvalancheAssets.LINKe_A_TOKEN,
      address(this),
      LINK_AMOUNT
    );

    // withdraw aLINK from the aave pool and receive LINK
    AaveV3Avalanche.POOL.withdraw(
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      LINK_AMOUNT,
      GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER
    );
  }
}
