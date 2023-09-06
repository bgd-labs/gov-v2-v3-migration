// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2PayloadEthereum} from 'aave-helpers/v2-config-engine/AaveV2PayloadEthereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

import {AaveV3PayloadEthereum, IEngine, EngineFlags, AaveV3EthereumAssets} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

contract TestV3Payload is AaveV3PayloadEthereum {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3EthereumAssets.CRV_UNDERLYING,
      supplyCap: 52_000_000,
      borrowCap: EngineFlags.KEEP_CURRENT
    });

    return capsUpdate;
  }
}

contract TestV2Payload is AaveV2PayloadEthereum {
  uint256 public constant CRV_LTV = 50_00; /// 49 -> 43
  uint256 public constant CRV_LIQUIDATION_THRESHOLD = 55_00; // 55 -> 49
  uint256 public constant CRV_LIQUIDATION_BONUS = 10800; //unchanged

  function _postExecute() internal override {
    AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
      AaveV2EthereumAssets.CRV_UNDERLYING,
      CRV_LTV,
      CRV_LIQUIDATION_THRESHOLD,
      CRV_LIQUIDATION_BONUS
    );
  }
}
