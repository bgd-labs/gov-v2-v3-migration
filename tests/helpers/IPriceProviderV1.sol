// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IPriceProviderV1 {
  function setFallbackOracle(address _fallbackOracle) external;
}
