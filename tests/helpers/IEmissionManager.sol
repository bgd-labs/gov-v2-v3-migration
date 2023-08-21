// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IEmissionManager {
  function setRewardsController(address controller) external;
}
