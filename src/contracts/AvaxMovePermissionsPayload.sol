// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract AvaxMovePermissionsPayload {
  address public constant AVALANCHE_LEVEL_1_EXECUTOR_V3 = address(6);
  address public constant CROSSCHAIN_CONTROLLER = address(44);

  // ~ 20 proposals
  uint256 public constant AVAX_AMOUNT = 120 ether;
  uint256 public constant LINK_AMOUNT = 122 ether;

  function execute() external {
    // CC FUNDING
    MigratorLib.fundCrosschainController(
      AaveV3Avalanche.COLLECTOR,
      AaveV3Avalanche.POOL,
      CROSSCHAIN_CONTROLLER,
      AaveV3AvalancheAssets.WAVAX_A_TOKEN,
      AVAX_AMOUNT,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3AvalancheAssets.LINKe_UNDERLYING,
      AaveV3AvalancheAssets.LINKe_A_TOKEN,
      LINK_AMOUNT,
      true
    );

    // V2 MARKETS
    MigratorLib.migrateV2MarketPermissions(
      AVALANCHE_LEVEL_1_EXECUTOR_V3,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV2Avalanche.ORACLE,
      AaveV2Avalanche.LENDING_RATE_ORACLE,
      AaveV2Avalanche.WETH_GATEWAY,
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY
    );
    // V3 MARKETS
    MigratorLib.migrateV3MarketPermissions(
      AVALANCHE_LEVEL_1_EXECUTOR_V3,
      AaveV3Avalanche.ACL_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
      AaveV3Avalanche.EMISSION_MANAGER,
      AaveV3Avalanche.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Avalanche.COLLECTOR,
      AaveMisc.PROXY_ADMIN_AVALANCHE,
      AaveV3Avalanche.WETH_GATEWAY,
      AaveV3Avalanche.SWAP_COLLATERAL_ADAPTER,
      AaveV3Avalanche.REPAY_WITH_COLLATERAL_ADAPTER
    );

    // Proof of reserve
    Ownable(AaveV2Avalanche.PROOF_OF_RESERVE).transferOwnership(AVALANCHE_LEVEL_1_EXECUTOR_V3);

    Ownable(AaveV3Avalanche.PROOF_OF_RESERVE).transferOwnership(AVALANCHE_LEVEL_1_EXECUTOR_V3);
    // one per network
    Ownable(AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR).transferOwnership(
      AVALANCHE_LEVEL_1_EXECUTOR_V3
    );

    // DefaultIncentivesController - need to be redeployed with the new params
    // Currently permission is held by separate multisig
  }
}
