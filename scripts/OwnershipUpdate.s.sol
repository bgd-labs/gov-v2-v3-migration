// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, ArbitrumScript, AvalancheScript, MetisScript, OptimismScript, PolygonScript, BaseScript, BNBScript, GnosisScript} from 'aave-helpers/ScriptUtils.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/interfaces/IWithGuardian.sol';
import {GovernanceV3Ethereum, GovernanceV3Arbitrum, GovernanceV3Avalanche, GovernanceV3Optimism, GovernanceV3Polygon, GovernanceV3Metis, GovernanceV3Base, GovernanceV3BNB, GovernanceV3Gnosis} from 'aave-address-book/AaveAddressBook.sol';
import {AaveV2Ethereum, AaveV2Polygon, AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';

// Effects of executing this changes on tenderly fork can be found here: https://github.com/bgd-labs/aave-permissions-list/pull/42

library SafeOwnable {
  function safeOwnershipTransfer(Ownable oldOwner, address newOwner) internal {
    require(newOwner != address(0), 'NEW_OWNER_CANT_BE_0');
    Ownable(oldOwner).transferOwnership(newOwner);
  }

  function safeGuardianTransfer(IWithGuardian oldGuardian, address newGuardian) internal {
    require(newGuardian != address(0), 'NEW_OWNER_CANT_BE_0');
    IWithGuardian(oldGuardian).updateGuardian(newGuardian);
  }
}

contract UpdateV3ContractsPermissionsEthereum {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Ethereum.EXECUTOR_LVL_1;

    address newGuardian = AaveV2Ethereum.EMERGENCY_ADMIN;
    address aDIGuardian = 0xb812d0944f8F581DfAA3a93Dda0d22EcEf51A9CF; // BGD Safe

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // remove deployer from allowed senders
    address[] memory sendersToRemove = new address[](1);
    sendersToRemove[0] = msg.sender;
    ICrossChainForwarder(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER).removeSenders(
      sendersToRemove
    );

    // change guardian
    IWithGuardian(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(aDIGuardian);

    // change ownership
    Ownable(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Ethereum.EMERGENCY_REGISTRY).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Ethereum.GOVERNANCE)).safeGuardianTransfer(newGuardian);
    IWithGuardian(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)).safeGuardianTransfer(
      newGuardian
    );

    // change ownership
    Ownable(address(GovernanceV3Ethereum.GOVERNANCE)).safeOwnershipTransfer(newOwner);
    Ownable(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_MACHINE).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_PORTAL_ETH_ETH).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_PORTAL_ETH_AVAX).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Ethereum.VOTING_PORTAL_ETH_POL).safeOwnershipTransfer(newOwner);
  }
}

contract Ethereum is EthereumScript, UpdateV3ContractsPermissionsEthereum {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsPolygon {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Polygon.EXECUTOR_LVL_1;
    address newGuardian = AaveV2Polygon.EMERGENCY_ADMIN;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // remove deployer from allowed senders
    address[] memory sendersToRemove = new address[](1);
    sendersToRemove[0] = msg.sender;
    ICrossChainForwarder(GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER).removeSenders(sendersToRemove);

    // change guardian
    IWithGuardian(GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Polygon.PAYLOADS_CONTROLLER)).safeGuardianTransfer(
      newGuardian
    );

    // change ownership
    Ownable(address(GovernanceV3Polygon.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Polygon.VOTING_MACHINE).safeOwnershipTransfer(newOwner);
  }
}

contract Polygon is PolygonScript, UpdateV3ContractsPermissionsPolygon {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsAvalanche {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Avalanche.EXECUTOR_LVL_1;
    address newGuardian = AaveV2Avalanche.EMERGENCY_ADMIN;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // remove deployer from allowed senders
    address[] memory sendersToRemove = new address[](1);
    sendersToRemove[0] = msg.sender;
    ICrossChainForwarder(GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER).removeSenders(
      sendersToRemove
    );

    // change guardian
    IWithGuardian(GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER)).safeGuardianTransfer(
      newGuardian
    );

    // change ownership
    Ownable(address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
    Ownable(GovernanceV3Avalanche.VOTING_MACHINE).safeOwnershipTransfer(newOwner);
  }
}

contract Avalanche is AvalancheScript, UpdateV3ContractsPermissionsAvalanche {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsArbitrum {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Arbitrum.EXECUTOR_LVL_1;

    address newGuardian = 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change guardian
    IWithGuardian(GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)).safeGuardianTransfer(
      newGuardian
    );

    // change ownership
    Ownable(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
  }
}

contract Arbitrum is ArbitrumScript, UpdateV3ContractsPermissionsArbitrum {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsOptimism {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Optimism.EXECUTOR_LVL_1;

    address newGuardian = 0xE50c8C619d05ff98b22Adf991F17602C774F785c;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change guardian
    IWithGuardian(GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)).safeGuardianTransfer(
      newGuardian
    );

    // change ownership
    Ownable(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
  }
}

contract Optimism is OptimismScript, UpdateV3ContractsPermissionsOptimism {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsBase {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Base.EXECUTOR_LVL_1;

    address newGuardian = 0x9e10C0A1Eb8FF6a0AaA53a62C7a338f35D7D9a2A;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change guardian
    IWithGuardian(GovernanceV3Base.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Base.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Base.PAYLOADS_CONTROLLER)).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(address(GovernanceV3Base.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
  }
}

contract Base is BaseScript, UpdateV3ContractsPermissionsBase {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsMetis {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Metis.EXECUTOR_LVL_1;

    address newGuardian = 0xF6Db48C5968A9eBCB935786435530f28e32Cc501;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change guardian
    IWithGuardian(GovernanceV3Metis.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Metis.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------
    // change guardian
    IWithGuardian(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
  }
}

contract Metis is MetisScript, UpdateV3ContractsPermissionsMetis {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

contract UpdateV3ContractsPermissionsGnosis {
  using SafeOwnable for Ownable;
  using SafeOwnable for IWithGuardian;

  function _changeOwnerAndGuardian() internal {
    address newOwner = GovernanceV3Gnosis.EXECUTOR_LVL_1;

    address newGuardian = 0xF163b8698821cefbD33Cf449764d69Ea445cE23D;

    // ------------- INFRASTRUCTURE CONTRACTS -----------------
    // change guardian
    IWithGuardian(GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);

    // change ownership
    Ownable(GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);

    // ------------- GOVERNANCE CONTRACTS -----------------

    // change guardian
    IWithGuardian(address(GovernanceV3Gnosis.PAYLOADS_CONTROLLER)).safeGuardianTransfer(
      newGuardian
    );
  }
}

contract Gnosis is GnosisScript, UpdateV3ContractsPermissionsGnosis {
  function run() external broadcast {
    _changeOwnerAndGuardian();
  }
}

//contract UpdateV3ContractsPermissionsBNB {
//  using SafeOwnable for Ownable;
//  using SafeOwnable for IWithGuardian;

//  function _changeOwnerAndGuardian() internal {
//    address newOwner = GovernanceV3BNB.EXECUTOR_LVL_1;
//    address newGuardian = address(0);
//
//    //change ownership of proxy admin TODO: get from address book when updated
//    Ownable(0x39EBFfc7679c62Dfcc4A3E2c09Bcb0be255Ae63c).safeOwnershipTransfer(newOwner);
//
//    // ------------- INFRASTRUCTURE CONTRACTS -----------------
//
//    // change guardian
//    IWithGuardian(GovernanceV3BNB.CROSS_CHAIN_CONTROLLER).safeGuardianTransfer(newGuardian);
//    // change ownership
//    Ownable(GovernanceV3BNB.CROSS_CHAIN_CONTROLLER).safeOwnershipTransfer(newOwner);
//
//    // ------------- GOVERNANCE CONTRACTS -----------------
//
//    // change guardian
//    IWithGuardian(address(GovernanceV3BNB.PAYLOADS_CONTROLLER)).safeGuardianTransfer(newGuardian);
//    // change ownership
//    Ownable(address(GovernanceV3BNB.PAYLOADS_CONTROLLER)).safeOwnershipTransfer(newOwner);
//  }
//}
//
//contract Binance is BNBScript, UpdateV3ContractsPermissionsBNB {
//  function run() external broadcast {
//    _changeOwnerAndGuardian();
//  }
//}
