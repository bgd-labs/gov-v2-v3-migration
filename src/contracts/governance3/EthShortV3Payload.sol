// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IExecutor as IExecutorV2} from '../dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IMediator} from '../interfaces/IMediator.sol';
import {IAaveCLRobotOperator} from '../dependencies/IAaveCLRobotOperator.sol';

/**
 * @title EthShortV3Payload
 * @notice Execute long permissions movement, fund governance robots, upgrade aAave implementation and
 * @notice accept admin of the existing short executor.
 * @author BGD Labs
 **/
contract EthShortV3Payload {
  using SafeCast for uint256;

  address public immutable MEDIATOR;

  // TODO: update address
  address public constant A_AAVE_IMPL = 0x6acCc155626E0CF8bFe97e68A17a567394D51238;

  // uint256 public constant ETH_AMOUNT_CROSSCHAIN_CONTROLLER = 0.2 ether;
  // uint256 public constant LINK_AMOUNT_CROSSCHAIN_CONTROLLER = 20 ether;

  // uint256 public constant LINK_AMOUNT_ROBOT_GOV_CHAIN = 300 ether;
  // uint256 public constant LINK_AMOUNT_ROBOT_VOTING_CHAIN = 100 ether;
  // uint256 public constant LINK_AMOUNT_ROBOT_EXECUTION_CHAIN = 400 ether;
  // uint256 public constant LINK_AMOUNT_ROOTS_CONSUMER = 100 ether;

  // uint256 public constant TOTAL_LINK_AMOUNT =
  //   LINK_AMOUNT_CROSSCHAIN_CONTROLLER +
  //     LINK_AMOUNT_ROBOT_GOV_CHAIN +
  //     LINK_AMOUNT_ROBOT_VOTING_CHAIN +
  //     LINK_AMOUNT_ROBOT_EXECUTION_CHAIN +
  //     LINK_AMOUNT_ROOTS_CONSUMER;

  // uint256 public constant GOV_V2_ROBOT_ID =
  //   38708010855340815800266444206792387479170521527111639306025178205742164078384;

  // address public constant ROBOT_OPERATOR = 0x020E452b463568f55BAc6Dc5aFC8F0B62Ea5f0f3;

  // address public constant GOV_CHAIN_ROBOT = 0x011824f238AEE05329213d5Ae029e899e5412343;
  // address public constant VOTING_CHAIN_ROBOT = 0x2cf0fA5b36F0f89a5EA18F835d1375974a7720B8;
  // address public constant EXECUTION_CHAIN_ROBOT = 0x365d47ceD3D7Eb6a9bdB3814aA23cc06B2D33Ef8;
  // address public constant ROOTS_CONSUMER = 0x2fA6F0A65886123AFD24A575aE4554d0FCe8B577;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // LONG ADMIN PERMISSIONS
    IMediator(MEDIATOR).execute();

    upgradeAAave();

    // GET LINK TOKENS FROM COLLECTOR
    // MigratorLib.fetchLinkTokens(
    //   AaveV3Ethereum.COLLECTOR,
    //   address(AaveV2Ethereum.POOL),
    //   AaveV2EthereumAssets.LINK_UNDERLYING,
    //   AaveV2EthereumAssets.LINK_A_TOKEN,
    //   TOTAL_LINK_AMOUNT,
    //   true
    // );

    // ROBOT
    // migrateKeepers();

    // EXECUTOR PERMISSIONS
    // new executor - call execute payload to accept new permissions
    IExecutorV2(AaveGovernanceV2.SHORT_EXECUTOR).acceptAdmin();
    // IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_1).executeTransaction(
    //   address(this),
    //   0,
    //   'acceptAdmin()',
    //   bytes(''),
    //   false
    // );
  }

  // function migrateKeepers() internal {
  //   // CANCEL PREVIOUS KEEPER
  //   IAaveCLRobotOperator(ROBOT_OPERATOR).cancel(GOV_V2_ROBOT_ID);

  //   // REGISTER NEW KEEPER (GOV CHAIN, VOTING CHAIN, EXECUTION CHAIN)
  //   IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).approve(
  //     ROBOT_OPERATOR,
  //     LINK_AMOUNT_ROBOT_GOV_CHAIN +
  //       LINK_AMOUNT_ROBOT_VOTING_CHAIN +
  //       LINK_AMOUNT_ROBOT_EXECUTION_CHAIN
  //   );

  //   IAaveCLRobotOperator(ROBOT_OPERATOR).register(
  //     'Governance Chain Keeper',
  //     GOV_CHAIN_ROBOT,
  //     5000000,
  //     LINK_AMOUNT_ROBOT_GOV_CHAIN.toUint96()
  //   );
  //   IAaveCLRobotOperator(ROBOT_OPERATOR).register(
  //     'Voting Chain Keeper',
  //     VOTING_CHAIN_ROBOT,
  //     5000000,
  //     LINK_AMOUNT_ROBOT_VOTING_CHAIN.toUint96()
  //   );
  //   IAaveCLRobotOperator(ROBOT_OPERATOR).register(
  //     'Execution Chain Keeper',
  //     EXECUTION_CHAIN_ROBOT,
  //     5000000,
  //     LINK_AMOUNT_ROBOT_EXECUTION_CHAIN.toUint96()
  //   );

  //   // FUND ROOTS CONSUMER
  //   IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).transfer(
  //     ROOTS_CONSUMER,
  //     LINK_AMOUNT_ROOTS_CONSUMER
  //   );

  //   // TRANSFER PERMISSION OF ROBOT OPERATOR
  //   IOwnable(ROBOT_OPERATOR).transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);
  // }

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
        params: bytes('') // this parameter is not actually used anywhere
      });

    AaveV3Ethereum.POOL_CONFIGURATOR.updateAToken(input);
  }
}
