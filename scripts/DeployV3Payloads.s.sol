// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, AvalancheScript, PolygonScript, BaseScript} from 'aave-helpers/ScriptUtils.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {GovV3Helpers} from 'aave-helpers/GovV3Helpers.sol';
import {IPayloadsControllerCore, PayloadsControllerUtils} from 'aave-address-book/GovernanceV3.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';

import {EthLongV3Payload} from '../src/contracts/governance3/EthLongV3Payload.sol';
import {EthShortV2Payload} from '../src/contracts/governance3/EthShortV2Payload.sol';
import {EthShortV3Payload} from '../src/contracts/governance3/EthShortV3Payload.sol';
import {AvalancheFundRobotPayload} from '../src/contracts/governance3/AvalancheFundRobotPayload.sol';
import {PolygonFundRobotPayload} from '../src/contracts/governance3/PolygonFundRobotPayload.sol';
import {BaseSwapsPayload} from '../src/contracts/governance3/BaseSwapsPayload.sol';
import {Mediator} from '../src/contracts/governance3/Mediator.sol';

contract DeployV3Payload {
  function _registerPayload(
    IPayloadsControllerCore payloadsController,
    address payload
  ) internal returns (uint40) {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(address(payload));

    return payloadsController.createPayload(actions);
  }
}

contract DeployMainnet is DeployV3Payload, EthereumScript {
  function run() external broadcast {
    Mediator mediator = Mediator(0xF60BDDE9077Be3226Db8109432d78afD92a8A003);

    EthShortV3Payload shortPayload = new EthShortV3Payload(address(mediator));
    _registerPayload(GovernanceV3Ethereum.PAYLOADS_CONTROLLER, address(shortPayload));
  }
}

contract DeployV2Mainnet is EthereumScript {
  function run() external broadcast {
    new EthShortV2Payload(42, 16, 8);
  }
}

contract DeployAvalanche is DeployV3Payload, AvalancheScript {
  function run() external broadcast {
    AvalancheFundRobotPayload payload = new AvalancheFundRobotPayload();
    _registerPayload(GovernanceV3Avalanche.PAYLOADS_CONTROLLER, address(payload));
  }
}

contract DeployPolygon is DeployV3Payload, PolygonScript {
  function run() external broadcast {
    PolygonFundRobotPayload payload = new PolygonFundRobotPayload();
    _registerPayload(GovernanceV3Polygon.PAYLOADS_CONTROLLER, address(payload));
  }
}

contract DeployBase is BaseScript {
  function run() external broadcast {
    new BaseSwapsPayload();
  }
}
