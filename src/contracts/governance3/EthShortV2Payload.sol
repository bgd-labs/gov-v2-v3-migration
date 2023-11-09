// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {PayloadsControllerUtils} from 'aave-address-book/GovernanceV3.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {IGovernance_V2_5} from 'aave-helpers/GovV3Helpers.sol';
import {ITransparentUpgradeableProxy} from '../dependencies/ITransparentUpgradeableProxy.sol';

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
  PayloadsControllerUtils.Payload[4] public payloads;

  constructor(
    uint40 mainnetPayloadId,
    uint40 polygonPayloadId,
    uint40 avalanchePayloadId,
    uint40 basePayloadId
  ) public {
    payloads[0] = PayloadsControllerUtils.Payload({
      chain: 1,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER),
      payloadId: mainnetPayloadId
    });
    payloads[1] = PayloadsControllerUtils.Payload({
      chain: 137,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Polygon.PAYLOADS_CONTROLLER),
      payloadId: polygonPayloadId
    });
    payloads[2] = PayloadsControllerUtils.Payload({
      chain: 43114,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER),
      payloadId: avalanchePayloadId
    });
    payloads[3] = PayloadsControllerUtils.Payload({
      chain: 8453,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: address(GovernanceV3Base.PAYLOADS_CONTROLLER),
      payloadId: basePayloadId
    });
  }

  function execute() external {
    // migrate ecosystem reserve
    _ecosystemReserve();

    // migrate aave arc gov executor to new gov v3 executor lvl 1
    _migrateArc();

    // call governance 2.5
    for (uint256 i = 0; i < payloads.length; i++) {
      IGovernance_V2_5(address(GovernanceV3Ethereum.GOVERNANCE)).forwardPayloadForExecution(
        payloads[i]
      );
    }
  }

  function _ecosystemReserve() internal {
    IOwnable(address(MiscEthereum.AAVE_ECOSYSTEM_RESERVE_CONTROLLER)).transferOwnership(
      MiscEthereum.PROXY_ADMIN
    );
    ITransparentUpgradeableProxy(MiscEthereum.ECOSYSTEM_RESERVE).changeAdmin(
      MiscEthereum.PROXY_ADMIN
    );
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
