// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {OwnableWithGuardian, IWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {MiscAvalanche} from 'aave-address-book/MiscAvalanche.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {MiscGnosis} from 'aave-address-book/MiscGnosis.sol';
import {MiscMetis} from 'aave-address-book/MiscMetis.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {GovernanceV3Gnosis, AaveV2Ethereum, GovernanceV3Ethereum, GovernanceV3Polygon, GovernanceV3Avalanche, GovernanceV3Arbitrum, GovernanceV3Optimism, GovernanceV3Base, GovernanceV3Metis, GovernanceV3Gnosis, GovernanceV3BNB, AaveGovernanceV2} from 'aave-address-book/AaveAddressBook.sol';
import {UpdateV3ContractsPermissionsGnosis, UpdateV3ContractsPermissionsEthereum, UpdateV3ContractsPermissionsBNB, UpdateV3ContractsPermissionsMetis, UpdateV3ContractsPermissionsBase, UpdateV3ContractsPermissionsOptimism, UpdateV3ContractsPermissionsArbitrum, UpdateV3ContractsPermissionsAvalanche, UpdateV3ContractsPermissionsPolygon} from '../scripts/OwnershipUpdate.s.sol';

contract MockImplementation is OwnableWithGuardian, Initializable {
  uint256 public constant TEST = 1;

  function initialize() external reinitializer(3) {}
}

interface IPayload {
  function execute() external;
}

abstract contract BaseTest is Test {
  MockImplementation pcImpl;

  function payloadsController() public view virtual returns (address);

  function proxyAdmin() public view virtual returns (address);

  function executorLvl1() public view virtual returns (address);

  function shortExecutor() public view virtual returns (address);

  function payload() public view virtual returns (address);

  function crossChainController() public view virtual returns (address);

  function _setUp() internal {
    pcImpl = new MockImplementation();

    if (payload() != address(0) && shortExecutor() != address(0)) {
      GovHelpers.executePayload(vm, address(payload()), shortExecutor());
    }

    vm.startPrank(executorLvl1());
    ProxyAdmin(proxyAdmin()).upgradeAndCall(
      TransparentUpgradeableProxy(payable(payloadsController())),
      address(pcImpl),
      abi.encodeWithSelector(MockImplementation.initialize.selector)
    );

    ProxyAdmin(proxyAdmin()).upgradeAndCall(
      TransparentUpgradeableProxy(payable(crossChainController())),
      address(pcImpl),
      abi.encodeWithSelector(MockImplementation.initialize.selector)
    );

    if (block.chainid == 1) {
      ProxyAdmin(proxyAdmin()).upgradeAndCall(
        TransparentUpgradeableProxy(payable(address(GovernanceV3Ethereum.GOVERNANCE))),
        address(pcImpl),
        abi.encodeWithSelector(MockImplementation.initialize.selector)
      );
    }

    vm.stopPrank();
  }

  function test_ImplementationUpdate() public {
    assertEq(MockImplementation(payloadsController()).TEST(), 1);
    assertEq(MockImplementation(crossChainController()).TEST(), 1);

    if (block.chainid == 1) {
      assertEq(MockImplementation(address(GovernanceV3Ethereum.GOVERNANCE)).TEST(), 1);
    }
  }
}

contract ProxyAdminTestEthereum is BaseTest, UpdateV3ContractsPermissionsEthereum {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscEthereum.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Ethereum.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.SHORT_EXECUTOR;
  }

  function payload() public pure override returns (address) {
    return 0xE40E84457F4b5075f1EB32352d81ecF1dE77fee6;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('mainnet', 18427147);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestPolygon is BaseTest, UpdateV3ContractsPermissionsPolygon {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Polygon.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscPolygon.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Polygon.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR;
  }

  function payload() public pure override returns (address) {
    return 0xc7751400F809cdB0C167F87985083C558a0610F7;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('polygon', 49131391);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestAvalanche is BaseTest, UpdateV3ContractsPermissionsAvalanche {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscAvalanche.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Avalanche.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return 0xa35b76E4935449E33C56aB24b23fcd3246f13470;
  }

  function payload() public pure override returns (address) {
    return 0x0A5a19f1c4a527773F8B6e7428255DD83b7A687b;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('avalanche', 36905462);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestArbitrum is BaseTest, UpdateV3ContractsPermissionsArbitrum {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscArbitrum.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Arbitrum.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR;
  }

  function payload() public pure override returns (address) {
    return 0xd0F0BC55Ac46f63A68F7c27fbFD60792C9571feA;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('arbitrum', 143889657);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestOptimism is BaseTest, UpdateV3ContractsPermissionsOptimism {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Optimism.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscOptimism.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Optimism.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR;
  }

  function payload() public pure override returns (address) {
    return 0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('optimism', 111322500);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestMetis is BaseTest, UpdateV3ContractsPermissionsMetis {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Metis.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscMetis.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Metis.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.METIS_BRIDGE_EXECUTOR;
  }

  function payload() public pure override returns (address) {
    return 0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Metis.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('metis', 9077368);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestBase is BaseTest, UpdateV3ContractsPermissionsBase {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Base.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscBase.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Base.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return AaveGovernanceV2.BASE_BRIDGE_EXECUTOR;
  }

  function payload() public pure override returns (address) {
    return 0x80a2F9a653d3990878cFf8206588fd66699E7f2a;
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Base.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('base', 5727316);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

contract ProxyAdminTestGnosis is BaseTest, UpdateV3ContractsPermissionsGnosis {
  function payloadsController() public pure override returns (address) {
    return address(GovernanceV3Gnosis.PAYLOADS_CONTROLLER);
  }

  function proxyAdmin() public pure override returns (address) {
    return MiscGnosis.PROXY_ADMIN;
  }

  function executorLvl1() public pure override returns (address) {
    return GovernanceV3Gnosis.EXECUTOR_LVL_1;
  }

  function shortExecutor() public pure override returns (address) {
    return address(0);
  }

  function payload() public pure override returns (address) {
    return address(0);
  }

  function crossChainController() public pure override returns (address) {
    return GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER;
  }

  function setUp() public {
    vm.createSelectFork('gnosis', 30633383);

    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
    _changeOwnerAndGuardian();
    vm.stopPrank();

    _setUp();
  }
}

//contract ProxyAdminTestBNB is BaseTest, UpdateV3ContractsPermissionsBNB {
//  function payloadsController() public pure override returns (address) {
//    return address(GovernanceV3BNB.PAYLOADS_CONTROLLER);
//  }
//
//  function proxyAdmin() public pure override returns (address) {
//    return MiscBNB.PROXY_ADMIN;
//  }
//
//  function executorLvl1() public pure override returns (address) {
//    return GovernanceV3BNB.EXECUTOR_LVL_1;
//  }
//
//  function shortExecutor() public pure override returns (address) {
//    return address(0);
//  }
//
//  function payload() public pure override returns (address) {
//    return address(0);
//  }
//
//  function crossChainController() public pure override returns (address) {
//    return GovernanceV3BNB.CROSS_CHAIN_CONTROLLER;
//  }
//
//  function setUp() public {
//    vm.createSelectFork('base', 5727316);
//
//    vm.startPrank(0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6);
//    _changeOwnerAndGuardian();
//    vm.stopPrank();
//
//    _setUp();
//  }
//}
