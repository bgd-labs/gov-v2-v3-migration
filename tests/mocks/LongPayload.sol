// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Mediator} from '../../src/contracts/Mediator.sol';

contract LongPayload {
  function execute(address mediatorAddress) public {
    Mediator mediator = Mediator(mediatorAddress);
    mediator.setOverdueDate();
  }
}
