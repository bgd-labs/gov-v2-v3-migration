// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IProofOfReserveExecutor {
  function disableAssets(address[] memory assets) external;
}
