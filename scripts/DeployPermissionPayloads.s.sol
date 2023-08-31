// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, ArbitrumScript, AvalancheScript, MetisScript, OptimismScript, PolygonScript} from 'aave-helpers/ScriptUtils.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ArbMovePermissionsPayload} from '../src/contracts/ArbMovePermissionsPayload.sol';
import {AvaxMovePermissionsPayload} from '../src/contracts/AvaxMovePermissionsPayload.sol';
import {EthLongMovePermissionsPayload} from '../src/contracts/EthLongMovePermissionsPayload.sol';
import {EthShortMovePermissionsPayload} from '../src/contracts/EthShortMovePermissionsPayload.sol';
import {MetisMovePermissionsPayload} from '../src/contracts/MetisMovePermissionsPayload.sol';
import {OptMovePermissionsPayload} from '../src/contracts/OptMovePermissionsPayload.sol';
import {PolygonMovePermissionsPayload} from '../src/contracts/PolygonMovePermissionsPayload.sol';

contract DeployMainnetPayload is EthereumScript {
  function run() external broadcast {
    new EthShortMovePermissionsPayload();
    new EthLongMovePermissionsPayload();
  }
}

contract DeployArbitrumPayload is ArbitrumScript {
  function run() external broadcast {
    new ArbMovePermissionsPayload();
  }
}

contract DeployAvalanchePayload is AvalancheScript {
  function run() external broadcast {
    new AvaxMovePermissionsPayload();
  }
}

contract DeployMetisPayload is MetisScript {
  function run() external broadcast {
    new MetisMovePermissionsPayload();
  }
}

contract DeployOptimismPayload is OptimismScript {
  function run() external broadcast {
    new OptMovePermissionsPayload();
  }
}

contract DeployPolygonPayload is PolygonScript {
  function run() external broadcast {
    new PolygonMovePermissionsPayload();
  }
}
