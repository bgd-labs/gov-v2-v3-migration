// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
// import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
// import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
// import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
// import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
// import {Mediator} from '../../src/contracts/governance3/Mediator.sol';
// import {EthShortV3Payload, IAaveArcTimelock} from '../../src/contracts/governance3/EthShortV3Payload.sol';

// contract ArcMigrationTest is ProtocolV3TestBase {
//   function setUp() public {
//     vm.createSelectFork(vm.rpcUrl('mainnet'), 18528409);

//     // deploy payload
//     Mediator mediator = new Mediator();
//     EthShortV3Payload payload = new EthShortV3Payload(address(mediator));

//     // execute payload
//     GovHelpers.executePayload(vm, address(payload), AaveGovernanceV2.SHORT_EXECUTOR);

//     // execute payload on arc timelock
//     uint256 currentActionId = IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).getActionsSetCount();
//     skip(3 days + 10);
//     IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).execute(currentActionId - 1);
//   }

//   function test_arcMigration() public {
//     assertEq(
//       IAaveArcTimelock(AaveGovernanceV2.ARC_TIMELOCK).getEthereumGovernanceExecutor(),
//       GovernanceV3Ethereum.EXECUTOR_LVL_1
//     );
//   }
// }
