// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

import {MigratorLib} from './MigratorLib.sol';

contract MetisMovePermissionsPayload {
  address public constant METIS_LEVEL_1_EXECUTOR_V3 = address(5);

  function execute() external {
    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      METIS_LEVEL_1_EXECUTOR_V3,
      AaveV3Metis.ACL_MANAGER,
      AaveV3Metis.POOL_ADDRESSES_PROVIDER,
      AaveV3Metis.EMISSION_MANAGER,
      AaveV3Metis.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Metis.COLLECTOR,
      AaveMisc.PROXY_ADMIN_METIS,
      address(0), // no need of wEthGateway because Metis token is ERC20 as well
      address(0), // swap collateral adapter not deployed yet
      address(0) // repay with collateral adapter not deployed yet
    );
  }
}
