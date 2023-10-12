// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStakedToken} from '../../src/contracts/dependencies/IStakedToken.sol';

contract ShortPayload {
  address public constant STK_AAVE_IMPL = 0x27FADCFf20d7A97D3AdBB3a6856CB6DedF2d2132;
  address public constant GHO_DEBT_TOKEN = address(33);

  function execute() public {
    IStakedToken(STK_AAVE_IMPL).setGHODebtToken(GHO_DEBT_TOKEN);
  }
}
