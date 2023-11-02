// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';
import {ConfigurableRightsPool} from '../src/ABPT/ABPT.sol';

contract DeployMainnet is EthereumScript {
  function run() external broadcast {
    new ConfigurableRightsPool();
  }
}
