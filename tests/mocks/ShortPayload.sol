// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';

contract ShortPayload {
  function execute() public {
    AaveV3Ethereum.POOL_ADDRESSES_PROVIDER.getPool();
  }
}
