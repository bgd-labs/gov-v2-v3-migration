// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, ArbitrumScript, AvalancheScript, MetisScript, OptimismScript, PolygonScript, BaseScript} from 'aave-helpers/ScriptUtils.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {ArbMovePermissionsPayload} from '../src/contracts/governance2.5/ArbMovePermissionsPayload.sol';
import {AvaxMovePermissionsPayload} from '../src/contracts/governance2.5/AvaxMovePermissionsPayload.sol';
import {EthShortMovePermissionsPayload} from '../src/contracts/governance2.5/EthShortMovePermissionsPayload.sol';
import {MetisMovePermissionsPayload} from '../src/contracts/governance2.5/MetisMovePermissionsPayload.sol';
import {OptMovePermissionsPayload} from '../src/contracts/governance2.5/OptMovePermissionsPayload.sol';
import {PolygonMovePermissionsPayload} from '../src/contracts/governance2.5/PolygonMovePermissionsPayload.sol';
import {BaseMovePermissionsPayload} from '../src/contracts/governance2.5/BaseMovePermissionsPayload.sol';

contract DeployMainnet is EthereumScript {
  function run() external broadcast {
    new EthShortMovePermissionsPayload();
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
