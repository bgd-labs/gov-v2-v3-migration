// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IStakedToken} from './dependencies/IStakedToken.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IWrappedTokenGateway} from './dependencies/IWrappedTokenGateway.sol';
import {IBalancerOwnable} from './dependencies/IBalancerOwnable.sol';
import {ILendingPoolAddressProviderV1} from './dependencies/ILendingPoolAddressProviderV1.sol';
import {IGhoAccessControl} from './dependencies/IGhoAccessControl.sol';
import {IMediator} from './interfaces/IMediator.sol';
import {MigratorLib} from './MigratorLib.sol';

contract EthShortMovePermissionsPayload {
  address public immutable MEDIATOR;

  address public constant A_AAVE_IMPL = 0xC383AAc4B3dC18D9ce08AB7F63B4632716F1e626;

  address payable public constant LEND_TO_AAVE_MIGRATOR =
    payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);
  address public constant AAVE_MERKLE_DISTRIBUTOR = 0xa88c6D90eAe942291325f9ae3c66f3563B93FE10;
  address payable public constant ABPT = payable(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);

  address public constant AAVE_V1_ADDRESS_PROVIDER = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

  address public constant AAVE_V1_PRICE_PROVIDER = 0x76B47460d7F7c5222cFb6b6A75615ab10895DDe4;

  address public constant STK_AAVE_ADDRESS = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
  address public constant STK_ABPT_ADDRESS = 0xa1116930326D21fB917d5A27F1E9943A9595fb47;

  // ~ 20 proposals
  uint256 public constant ETH_AMOUNT = 2 ether;
  uint256 public constant LINK_AMOUNT = 9 ether;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // CC FUNDING
    MigratorLib.fundCrosschainController(
      AaveV3Ethereum.COLLECTOR,
      AaveV3Ethereum.POOL,
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      AaveV3EthereumAssets.WETH_A_TOKEN,
      ETH_AMOUNT,
      AaveV3Ethereum.WETH_GATEWAY,
      AaveV3EthereumAssets.LINK_UNDERLYING,
      address(0),
      LINK_AMOUNT,
      false
    );

    // STK TOKENS - SET ADMIN ROLES
    IStakedToken stkAave = IStakedToken(STK_AAVE_ADDRESS);
    IStakedToken stkABPT = IStakedToken(STK_ABPT_ADDRESS);

    stkAave.setPendingAdmin(stkAave.SLASH_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkAave.setPendingAdmin(stkAave.COOLDOWN_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkAave.setPendingAdmin(stkAave.CLAIM_HELPER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    stkABPT.setPendingAdmin(stkABPT.SLASH_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkABPT.setPendingAdmin(stkABPT.COOLDOWN_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkABPT.setPendingAdmin(stkABPT.CLAIM_HELPER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.SLASH_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.COOLDOWN_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.CLAIM_HELPER_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.SLASH_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.COOLDOWN_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.CLAIM_HELPER_ROLE()),
      false
    );

    // GHO
    migrateGHOPermissions();

    // V1 POOL
    migrateV1Pool();

    // V2 POOL
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV2Ethereum.ORACLE,
      AaveV2Ethereum.LENDING_RATE_ORACLE,
      AaveV2Ethereum.WETH_GATEWAY,
      AaveV2Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY
    );
    MigratorLib.migrateV2PoolPermissions(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER,
      AaveV2EthereumAMM.ORACLE,
      AaveV2EthereumAMM.LENDING_RATE_ORACLE,
      AaveV2EthereumAMM.WETH_GATEWAY,
      AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER_REGISTRY
    );

    // V3 POOL
    MigratorLib.migrateV3PoolPermissions(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      AaveV3Ethereum.ACL_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      AaveV3Ethereum.EMISSION_MANAGER,
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER_REGISTRY,
      AaveV3Ethereum.COLLECTOR,
      AaveMisc.PROXY_ADMIN_ETHEREUM,
      AaveV3Ethereum.WETH_GATEWAY,
      AaveV3Ethereum.SWAP_COLLATERAL_ADAPTER,
      AaveV3Ethereum.REPAY_WITH_COLLATERAL_ADAPTER,
      AaveV3Ethereum.WITHDRAW_SWAP_ADAPTER
    );

    // MISC ECOSYSTEM

    // MerkleDistributor
    IOwnable(AAVE_MERKLE_DISTRIBUTOR).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // LendToAave Migrator
    TransparentUpgradeableProxy(LEND_TO_AAVE_MIGRATOR).changeAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM);

    // Safety module
    TransparentUpgradeableProxy(ABPT).changeAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM);
    IBalancerOwnable(ABPT).setController(AaveMisc.PROXY_ADMIN_ETHEREUM);

    IOwnable(AaveMisc.AAVE_SWAPPER_ETHEREUM).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    IOwnable(AaveMisc.AAVE_POL_ETH_BRIDGE).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // EXECUTOR PERMISSIONS

    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_1));

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(this),
      0,
      'acceptAdmin()',
      bytes(''),
      false
    );

    // new executor - change owner to payload controller
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_1).transferOwnership(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );

    // LONG ADMIN PERMISSIONS
    IMediator(MEDIATOR).execute();
  }

  function migrateStkPermissions() internal {
    IStakedToken stkAave = IStakedToken(STK_AAVE_ADDRESS);
    IStakedToken stkABPT = IStakedToken(STK_ABPT_ADDRESS);

    stkAave.setPendingAdmin(stkAave.SLASH_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkAave.setPendingAdmin(stkAave.COOLDOWN_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkAave.setPendingAdmin(stkAave.CLAIM_HELPER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    stkABPT.setPendingAdmin(stkABPT.SLASH_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkABPT.setPendingAdmin(stkABPT.COOLDOWN_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    stkABPT.setPendingAdmin(stkABPT.CLAIM_HELPER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.SLASH_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.COOLDOWN_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkAave),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkAave.CLAIM_HELPER_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.SLASH_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.COOLDOWN_ADMIN_ROLE()),
      false
    );

    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
      address(stkABPT),
      0,
      'claimRoleAdmin(uint256)',
      abi.encode(stkABPT.CLAIM_HELPER_ROLE()),
      false
    );
  }

  function migrateV1Pool() internal {
    // lending pool manager
    ILendingPoolAddressProviderV1(AAVE_V1_ADDRESS_PROVIDER).setLendingPoolManager(
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );

    // owner of address provider
    IOwnable(AAVE_V1_ADDRESS_PROVIDER).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    // owner of price provider
    IOwnable(AAVE_V1_PRICE_PROVIDER).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);
  }

  function migrateGHOPermissions() internal {
    IGhoAccessControl ghoToken = IGhoAccessControl(AaveV3Ethereum.GHO_TOKEN);

    ghoToken.grantRole(ghoToken.DEFAULT_ADMIN_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ghoToken.grantRole(ghoToken.FACILITATOR_MANAGER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ghoToken.grantRole(ghoToken.BUCKET_MANAGER_ROLE(), GovernanceV3Ethereum.EXECUTOR_LVL_1);
  }

  function upgradeAAave() internal {
    // update aAave implementation

    ConfiguratorInputTypes.UpdateATokenInput memory input = ConfiguratorInputTypes
      .UpdateATokenInput({
        asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
        treasury: address(AaveV3Ethereum.COLLECTOR),
        incentivesController: AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
        name: 'Aave Ethereum AAVE',
        symbol: 'aEthAAVE',
        implementation: A_AAVE_IMPL,
        params: '0x10' // this parameter is not actually used anywhere
      });

    AaveV3Ethereum.POOL_CONFIGURATOR.updateAToken(input);
  }
}
