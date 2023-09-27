// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, ArbitrumScript, AvalancheScript, MetisScript, OptimismScript, PolygonScript, BaseScript} from 'aave-helpers/ScriptUtils.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ArbMovePermissionsPayload} from '../src/contracts/ArbMovePermissionsPayload.sol';
import {AvaxMovePermissionsPayload} from '../src/contracts/AvaxMovePermissionsPayload.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';
import {EthShortMovePermissionsPayload} from '../src/contracts/EthShortMovePermissionsPayload.sol';
import {MetisMovePermissionsPayload} from '../src/contracts/MetisMovePermissionsPayload.sol';
import {OptMovePermissionsPayload} from '../src/contracts/OptMovePermissionsPayload.sol';
import {PolygonMovePermissionsPayload} from '../src/contracts/PolygonMovePermissionsPayload.sol';
import {BaseMovePermissionsPayload} from '../src/contracts/BaseMovePermissionsPayload.sol';
import {Mediator} from '../src/contracts/Mediator.sol';

contract DeployMainnet is EthereumScript {
  function run() external broadcast {
    Mediator mediator = new Mediator();
    new EthShortMovePermissionsPayload(address(mediator));
    new EthLongMovePermissionsPayload(address(mediator));
  }
}

contract DeployArbitrum is ArbitrumScript {
  function run() external broadcast {
    new ArbMovePermissionsPayload();
  }
}

contract DeployAvalanche is AvalancheScript {
  function run() external broadcast {
    new AvaxMovePermissionsPayload();
  }
}

contract DeployMetis is MetisScript {
  function run() external broadcast {
    new MetisMovePermissionsPayload();
  }
}

contract DeployOptimism is OptimismScript {
  function run() external broadcast {
    new OptMovePermissionsPayload();
  }
}

contract DeployPolygon is PolygonScript {
  function run() external broadcast {
    new PolygonMovePermissionsPayload();
  }
}

contract DeployBase is BaseScript {
  function run() external broadcast {
    new BaseMovePermissionsPayload();
  }
}
