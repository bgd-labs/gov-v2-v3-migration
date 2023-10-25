// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
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
import {GovernanceV3Ethereum, GovernanceV3Polygon, GovernanceV3Avalanche, GovernanceV3Arbitrum, GovernanceV3Optimism, GovernanceV3Base, GovernanceV3Metis, GovernanceV3Gnosis, GovernanceV3BNB, AaveGovernanceV2} from 'aave-address-book/AaveAddressBook.sol';

//https://snowtrace.io/address/0x0a5a19f1c4a527773f8b6e7428255dd83b7a687b
//https://arbiscan.io/address/0xd0f0bc55ac46f63a68f7c27fbfd60792c9571fea
//https://optimistic.etherscan.io/address/0xab22988d93d5f942fc6b6c6ea285744809d1d9cc
//https://andromeda-explorer.metis.io/address/0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45/
//https://basescan.org/address/0x80a2f9a653d3990878cff8206588fd66699e7f2a

contract MockImplementation is Initializable {
  uint256 public constant TEST = 1;

  function initialize() external reinitializer(2) {}
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

  function _setUp() internal {
    pcImpl = new MockImplementation();

    GovHelpers.executePayload(vm, address(payload()), shortExecutor());

    hoax(executorLvl1());
    ProxyAdmin(proxyAdmin()).upgradeAndCall(
      TransparentUpgradeableProxy(payable(payloadsController())),
      address(pcImpl),
      abi.encodeWithSelector(MockImplementation.initialize.selector)
    );
  }

  function test_ImplementationUpdate() public {
    assertEq(MockImplementation(payloadsController()).TEST(), 1);
  }
}

contract ProxyAdminTestEthereum is BaseTest {
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

  function setUp() public {
    vm.createSelectFork('mainnet', 18427147);

    _setUp();
  }
}

contract ProxyAdminTestPolygon is BaseTest {
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

  function setUp() public {
    vm.createSelectFork('polygon', 49131391);
    _setUp();
  }
}