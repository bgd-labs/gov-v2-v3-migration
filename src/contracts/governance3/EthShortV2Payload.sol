// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {ITransparentUpgradeableProxy} from '../dependencies/ITransparentUpgradeableProxy.sol';
import {IProxyAdmin} from '../dependencies/IProxyAdmin.sol';
import {IExecutor as IExecutorV2} from '../dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IMediator} from '../interfaces/IMediator.sol';
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';
import {MigratorLib} from '../libraries/MigratorLib.sol';

interface IAaveArcTimelock {
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) external;

  function updateEthereumGovernanceExecutor(address ethereumGovernanceExecutor) external;

  function getActionsSetCount() external view returns (uint256);

  function execute(uint256 actionsSetId) external;

  function getDelay() external view returns (uint256);

  function getEthereumGovernanceExecutor() external view returns (address);

  function getCurrentState(uint256 actionsSetId) external view returns (uint8);
}

/**
 * @title EthShortV2Payload
 * @notice Migrate ethereum executor of the ARC and ecosystem reserve, queue gov v 2.5 execution
 * @author BGD Labs
 **/
contract EthShortV2Payload {
  function execute() external {
    // migrate ecosystem reserve
    _ecosystemReserve();

    // migrate aave arc gov executor to new gov v3 executor lvl 1
    _migrateArc();
  }

  function _ecosystemReserve() internal {
    IOwnable(address(MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER)).transferOwnership(
      MiscEthereum.PROXY_ADMIN
    );
    ITransparentUpgradeableProxy(MiscEthereum.ECOSYSTEM_RESERVE).changeAdmin(
      MiscEthereum.PROXY_ADMIN
    );

    // call Governance 2.5
  }

  function _migrateArc() internal {
    address[] memory targets = new address[](1);
    targets[0] = AaveGovernanceV2.ARC_TIMELOCK;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'updateEthereumGovernanceExecutor(address)';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encode(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    // create payload for arc timelock
    IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).queue(
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls
    );
  }
}
