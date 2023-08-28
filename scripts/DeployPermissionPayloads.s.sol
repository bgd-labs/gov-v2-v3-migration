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
  address public constant LEVEL_1_EXECUTOR_V3 = address(1);
  address public constant LEVEL_2_EXECUTOR_V3 = address(2);

  // TODO: this should be get from address-book
  function run() external broadcast {
    new EthShortMovePermissionsPayload(LEVEL_1_EXECUTOR_V3);
    new EthLongMovePermissionsPayload(LEVEL_2_EXECUTOR_V3, address(0), address(0));
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
