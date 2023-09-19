// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2PayloadEthereum} from 'aave-helpers/v2-config-engine/AaveV2PayloadEthereum.sol';
import {AaveV2PayloadPolygon} from 'aave-helpers/v2-config-engine/AaveV2PayloadPolygon.sol';
import {AaveV2PayloadAvalanche} from 'aave-helpers/v2-config-engine/AaveV2PayloadAvalanche.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2Polygon, AaveV2PolygonAssets} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV2Avalanche, AaveV2AvalancheAssets} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Base, AaveV3BaseAssets} from 'aave-address-book/AaveV3Base.sol';
import {AaveV3Metis, AaveV3MetisAssets} from 'aave-address-book/AaveV3Metis.sol';

import {AaveV3PayloadEthereum, IEngine, EngineFlags, AaveV3EthereumAssets} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';
import {AaveV3PayloadPolygon} from 'aave-helpers/v3-config-engine/AaveV3PayloadPolygon.sol';
import {AaveV3PayloadAvalanche} from 'aave-helpers/v3-config-engine/AaveV3PayloadAvalanche.sol';
import {AaveV3PayloadArbitrum} from 'aave-helpers/v3-config-engine/AaveV3PayloadArbitrum.sol';
import {AaveV3PayloadOptimism} from 'aave-helpers/v3-config-engine/AaveV3PayloadOptimism.sol';
import {AaveV3PayloadBase} from 'aave-helpers/v3-config-engine/AaveV3PayloadBase.sol';
import {AaveV3PayloadMetis} from 'aave-helpers/v3-config-engine/AaveV3PayloadMetis.sol';

contract TestV3PayloadEthereum is AaveV3PayloadEthereum {
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

contract TestV2PayloadEthereum is AaveV2PayloadEthereum {
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

contract TestV3PayloadPolygon is AaveV3PayloadPolygon {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3PolygonAssets.WETH_UNDERLYING,
      supplyCap: 0,
      borrowCap: EngineFlags.KEEP_CURRENT
    });

    return capsUpdate;
  }
}

contract TestV2PayloadPolygon is AaveV2PayloadPolygon {
  function _postExecute() internal override {
    AaveV2Polygon.POOL_CONFIGURATOR.configureReserveAsCollateral(
      AaveV2PolygonAssets.WETH_UNDERLYING,
      0,
      55_00,
      10800
    );
  }
}

contract TestV3PayloadAvalanche is AaveV3PayloadAvalanche {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3AvalancheAssets.WETHe_UNDERLYING,
      supplyCap: 0,
      borrowCap: EngineFlags.KEEP_CURRENT
    });

    return capsUpdate;
  }
}

contract TestV2PayloadAvalanche is AaveV2PayloadAvalanche {
  function _postExecute() internal override {
    AaveV2Avalanche.POOL_CONFIGURATOR.configureReserveAsCollateral(
      AaveV2AvalancheAssets.WETHe_UNDERLYING,
      0,
      55_00,
      10800
    );
  }
}

contract TestV3PayloadArbitrum is AaveV3PayloadArbitrum {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3ArbitrumAssets.WETH_UNDERLYING,
      supplyCap: 0,
      borrowCap: EngineFlags.KEEP_CURRENT
    });

    return capsUpdate;
  }
}

contract TestV3PayloadOptimism is AaveV3PayloadOptimism {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3OptimismAssets.WETH_UNDERLYING,
      supplyCap: 0,
      borrowCap: EngineFlags.KEEP_CURRENT
    });

    return capsUpdate;
  }
}

//contract TestV3PayloadBase is AaveV3PayloadBase {
//  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
//    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);
//
//    capsUpdate[0] = IEngine.CapsUpdate({
//      asset: AaveV3BaseAssets.WETH_UNDERLYING,
//      supplyCap: 0,
//      borrowCap: EngineFlags.KEEP_CURRENT
//    });
//
//    return capsUpdate;
//  }
//}

contract TestV3PayloadMetis is AaveV3PayloadMetis {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3MetisAssets.WETH_UNDERLYING,
      supplyCap: 0,
      borrowCap: EngineFlags.KEEP_CURRENT
    });

    return capsUpdate;
  }
}
