// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';

import {EthereumScript, ArbitrumScript, AvalancheScript, MetisScript, OptimismScript, PolygonScript, BaseScript, BNBScript, GnosisScript} from 'aave-helpers/ScriptUtils.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/interfaces/IWithGuardian.sol';
import {GovernanceV3Ethereum, GovernanceV3Arbitrum, GovernanceV3Avalanche, GovernanceV3Optimism, GovernanceV3Polygon, GovernanceV3Metis, GovernanceV3Base, GovernanceV3BNB, GovernanceV3Gnosis} from 'aave-address-book/AaveAddressBook.sol';
import {AaveV2Ethereum, AaveV2Polygon, AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';

// Effects of executing this changes on tenderly fork can be found here: https://github.com/bgd-labs/aave-permissions-list/pull/42

abstract contract UpdateV3Permissions is Script {
  modifier broadcastV2() {
    vm.startBroadcast();
    _;
    vm.stopBroadcast();
  }

  function targetOwner() public pure virtual returns (address);

  function targetGovernanceGuardian() public pure virtual returns (address);

  function targetADIGuardian() public pure virtual returns (address);

  function govContractsToUpdate() public pure virtual returns (address[] memory);

  function aDIContractsToUpdate() public pure virtual returns (address[] memory);

  // @dev should be set not to 0x0 if requires removal of msg.sender from allowed senders
  function CROSS_CHAIN_CONTROLLER() public pure virtual returns (address) {
    return address(0);
  }

  function _removeFromAllowedSenders() internal {
    if (CROSS_CHAIN_CONTROLLER() != address(0)) {
      address[] memory sendersToRemove = new address[](1);
      sendersToRemove[0] = msg.sender;
      ICrossChainForwarder(CROSS_CHAIN_CONTROLLER()).removeSenders(sendersToRemove);
    }
  }

  function _changeOwnerAndGuardian(
    address owner,
    address guardian,
    address[] memory contracts
  ) internal {
    require(owner != address(0), 'NEW_OWNER_CANT_BE_0');
    require(guardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');

    for (uint256 i = 0; i < contracts.length; i++) {
      OwnableWithGuardian contractWithAC = OwnableWithGuardian(contracts[i]);
      try contractWithAC.guardian() returns (address currentGuardian) {
        if (currentGuardian != guardian) {
          IWithGuardian(contracts[i]).updateGuardian(guardian);
        }
      } catch {}
      if (contractWithAC.owner() != owner) {
        contractWithAC.transferOwnership(owner);
      }
    }
  }

  function run() external broadcastV2 {
    _removeFromAllowedSenders();
    _changeOwnerAndGuardian(targetOwner(), targetGovernanceGuardian(), govContractsToUpdate());
    _changeOwnerAndGuardian(targetOwner(), targetADIGuardian(), aDIContractsToUpdate());
  }
}

contract UpdateV3ContractsPermissionsEthereum is UpdateV3Permissions, EthereumScript {
  function targetOwner() public pure override returns (address) {
    return GovernanceV3Ethereum.EXECUTOR_LVL_1;
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return AaveV2Ethereum.EMERGENCY_ADMIN;
  }

  function targetADIGuardian() public pure override returns (address) {
    return 0xb812d0944f8F581DfAA3a93Dda0d22EcEf51A9CF; // BGD Safe
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER;
  }

  function govContractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](2);
    contracts[0] = address(GovernanceV3Ethereum.GOVERNANCE);
    contracts[1] = address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER);
    return contracts;
  }
}

  function aDIContractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](6);
    contracts[0] = GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER;
    contracts[1] = GovernanceV3Ethereum.EMERGENCY_REGISTRY;
    contracts[2] = GovernanceV3Ethereum.VOTING_MACHINE;
    contracts[3] = GovernanceV3Ethereum.VOTING_PORTAL_ETH_ETH;
    contracts[4] = GovernanceV3Ethereum.VOTING_PORTAL_ETH_AVAX;
    contracts[5] = GovernanceV3Ethereum.VOTING_PORTAL_ETH_POL;
    return contracts;
  }
}

contract UpdateV3ContractsPermissionsPolygon is UpdateV3Permissions, PolygonScript {
  function targetOwner() public pure override returns (address) {
    return GovernanceV3Polygon.EXECUTOR_LVL_1;
  }

  function targetGovernanceGuardian() public pure virtual returns (address) {
    return AaveV2Polygon.EMERGENCY_ADMIN;
  }

  function targetADIGuardian() public pure virtual returns (address) {
    return 0xbCEB4f363f2666E2E8E430806F37e97C405c130b;
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER;
  }

  function govContractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](2);
    contracts[0] = address(GovernanceV3Polygon.PAYLOADS_CONTROLLER);
    contracts[1] = GovernanceV3Polygon.VOTING_MACHINE;
    return contracts;
  }
  function aDIContractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](1);
    contracts[0] = GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER;
    return contracts;
  }
}

contract UpdateV3ContractsPermissionsAvalanche is UpdateV3Permissions, AvalancheScript {
  function targetOwner() public pure override returns (address) {
    return GovernanceV3Avalanche.EXECUTOR_LVL_1;
  }

  function targetGovernanceGuardian() public pure virtual returns (address) {
    return AaveV2Avalanche.EMERGENCY_ADMIN;
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER;
  }

  function contractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](3);
    contracts[0] = GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER;
    contracts[1] = address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER);
    contracts[2] = GovernanceV3Avalanche.VOTING_MACHINE;
    return contracts;
  }
}

contract UpdateV3ContractsPermissionsArbitrum is UpdateV3Permissions, ArbitrumScript {
  function targetOwner() public pure override returns (address) {
    return GovernanceV3Arbitrum.EXECUTOR_LVL_1;
  }

  function targetGovernanceGuardian() public pure virtual returns (address) {
    return 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb; // normal arb guardian
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER;
  }

  function contractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](2);
    contracts[0] = GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER;
    contracts[1] = address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER);
    return contracts;
  }
}

contract UpdateV3ContractsPermissionsArbitrum {
  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Arbitrum.EXECUTOR_LVL_1;
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');

    address newGuardian = 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change guardian
    IWithGuardian(GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // change ownership
    Ownable(GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);

    // change ownership
    Ownable(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
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
    // change guardian
    IWithGuardian(GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // change ownership
    Ownable(GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);

    // change ownership
    Ownable(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
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
    // change guardian
    IWithGuardian(GovernanceV3Base.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // change ownership
    Ownable(GovernanceV3Base.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Base.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);

    // change ownership
    Ownable(address(GovernanceV3Base.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
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
    // change guardian
    IWithGuardian(GovernanceV3Metis.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // change ownership
    Ownable(GovernanceV3Metis.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);

    // change ownership
    Ownable(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
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
    // change guardian
    IWithGuardian(GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);

    // change ownership
    Ownable(GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);

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
//
//    // change guardian
//    IWithGuardian(GovernanceV3BNB.CROSS_CHAIN_CONTROLLER).updateGuardian(newGuardian);
//    // change ownership
//    Ownable(GovernanceV3BNB.CROSS_CHAIN_CONTROLLER).transferOwnership(newOwner);
//
//    // ------------- GOVERNANCE CONTRACTS -----------------
//
//    // change guardian
//    IWithGuardian(address(GovernanceV3BNB.PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
//    // change ownership
//    Ownable(address(GovernanceV3BNB.PAYLOADS_CONTROLLER)).transferOwnership(newOwner);
//  }
//}
//
//contract Binance is BNBScript, UpdateV3ContractsPermissionsBNB {
//  function run() external broadcast {
//    _changeOwnerAndGuardian();
//  }
//}
