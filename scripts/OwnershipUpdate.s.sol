// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, ArbitrumScript, AvalancheScript, MetisScript, OptimismScript, PolygonScript, BaseScript, BNBScript, GnosisScript} from 'aave-helpers/ScriptUtils.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/interfaces/IWithGuardian.sol';
import {GovernanceV3Ethereum, GovernanceV3Arbitrum, GovernanceV3Avalanche, GovernanceV3Optimism, GovernanceV3Polygon, GovernanceV3Metis, GovernanceV3Base, GovernanceV3BNB, GovernanceV3Gnosis} from 'aave-address-book/AaveAddressBook.sol';
import {AaveV2Ethereum, AaveV2Polygon, AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';

contract UpdateV3ContractsPermissionsEthereum {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = AaveV2Ethereum.EMERGENCY_ADMIN;
    require(newGuardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);
    Ownable(GovernanceV3Ethereum.EMERGENCY_REGISTRY).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Ethereum.GOVERNANCE)).transferOwnership(newOwner); // TODO: should it be long or short?
    Ownable(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_MACHINE).transferOwnership(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_PORTAL_ETH_ETH).transferOwnership(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_PORTAL_ETH_AVAX).transferOwnership(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_PORTAL_ETH_POL).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Ethereum.GOVERNANCE)).updateGuardian(newGuardian);
    IWithGuardian(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Ethereum is EthereumScript, UpdateV3ContractsPermissionsEthereum {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsPolygon {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Polygon.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = AaveV2Polygon.EMERGENCY_ADMIN;
    require(newGuardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Polygon.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
    Ownable(GovernanceV3Polygon.VOTING_MACHINE).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Polygon.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Polygon is PolygonScript, UpdateV3ContractsPermissionsPolygon {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsAvalanche {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Avalanche.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = AaveV2Avalanche.EMERGENCY_ADMIN;
    require(newGuardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
    Ownable(GovernanceV3Avalanche.VOTING_MACHINE).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Avalanche is AvalancheScript, UpdateV3ContractsPermissionsAvalanche {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsArbitrum {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Arbitrum.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Arbitrum is ArbitrumScript, UpdateV3ContractsPermissionsArbitrum {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsOptimism {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Optimism.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = 0xE50c8C619d05ff98b22Adf991F17602C774F785c;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Optimism is OptimismScript, UpdateV3ContractsPermissionsOptimism {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsBase {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Base.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = 0x9e10C0A1Eb8FF6a0AaA53a62C7a338f35D7D9a2A;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Base.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Base.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Base.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Base.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Base is BaseScript, UpdateV3ContractsPermissionsBase {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsMetis {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Metis.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = 0xF6Db48C5968A9eBCB935786435530f28e32Cc501;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Metis.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Metis.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change ownership
    Ownable(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Metis is MetisScript, UpdateV3ContractsPermissionsMetis {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsGnosis {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Gnosis.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = 0xF163b8698821cefbD33Cf449764d69Ea445cE23D;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change ownership
    Ownable(GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // change guardian
    IWithGuardian(GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // ------------- GOVERNANCE CONTRACTS -----------------

    // change guardian
    IWithGuardian(address(GovernanceV3Gnosis.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}

contract Gnosis is GnosisScript, UpdateV3ContractsPermissionsGnosis {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

//contract UpdateV3ContractsPermissionsBNB {
//  function _changeOwnerAndGuardian() internal {
//    address newOwner = GovernanceV3BNB.EXECUTOR_LVL_1;
//    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');
//
//    address newGuardian = address(0);
//    require(newGuardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');
//
//    //change ownership of proxy admin TODO: get from address book when updated
//    Ownable(0x39EBFfc7679c62Dfcc4A3E2c09Bcb0be255Ae63c).transferOwnership(newOwner);
//
//    // ------------- INFRASTRUCTURE CONTRACTS -----------------
//    // change ownership
//    Ownable(GovernanceV3BNB.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);
//
//    // change guardian
//    IWithGuardian(GovernanceV3BNB.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);
//
//    // ------------- GOVERNANCE CONTRACTS -----------------
//    // change ownership
//    Ownable(address(GovernanceV3BNB.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
//
//    // change guardian
//    IWithGuardian(address(GovernanceV3BNB.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
//  }
//}
//
//contract Binance is BNBScript, UpdateV3ContractsPermissionsBNB {
//  function run() external broadcast {
//    _changeOwnerAndGuardian();
//  }
//}
