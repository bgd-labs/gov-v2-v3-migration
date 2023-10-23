// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ILendingPoolConfiguratorV1 {
  function freezeReserve(address _reserve) external;
}
