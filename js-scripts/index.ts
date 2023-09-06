import 'dotenv/config';
import {tenderly} from '@bgd-labs/aave-cli';
import path from 'path';
import {createPublicClient, createWalletClient, http} from 'viem';
import {mainnet} from 'viem/chains';
import {
  deployAAaveImpl,
  deployAAaveTokenPayload,
  deployAaveImpl,
  deployAaveTokenPayload,
  deployLongPermissionsPayload,
  deployShortPermissionsPayload,
  deployStkAaveImpl,
  deployStkAaveTokenPayload,
} from './payloadsV2';
import {createV2Proposal, executeV2Proposals} from './proposalsV2';
import {AaveGovernanceV2, GovernanceV3Ethereum, AaveMisc} from '@bgd-labs/aave-address-book';
import {changeExecutorsOwner, deployVotingMachine, deployVotingPortal} from './proposalsV3';

export const DEPLOYER = '0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6';
// create mainnet fork
const getFork = async () => {
  return tenderly.fork({chainId: 1, alias: 'govV3Fork'});
};

const deployPayloadsV2 = async () => {
  const fork = await getFork();

  const walletClient = createWalletClient({
    account: AaveMisc.ECOSYSTEM_RESERVE,
    chain: {...mainnet, id: 3030, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  const publicClient = createPublicClient({
    chain: {...mainnet, id: 3030, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  // deploy token implementations
  const aaveTokenV3Impl = await deployAaveImpl(walletClient, publicClient, DEPLOYER);
  const stkAaveTokenV3 = await deployStkAaveImpl(walletClient, publicClient, DEPLOYER);
  const aAaveTokenV3 = await deployAAaveImpl(walletClient, publicClient, DEPLOYER);

  // deploy token payloads
  const aaveTokenPayload = await deployAaveTokenPayload(
    walletClient,
    publicClient,
    DEPLOYER,
    aaveTokenV3Impl
  );
  const stkAaveTokenPayload = await deployStkAaveTokenPayload(
    walletClient,
    publicClient,
    DEPLOYER,
    stkAaveTokenV3
  );
  const aAaveTokenPayload = await deployAAaveTokenPayload(
    walletClient,
    publicClient,
    DEPLOYER,
    aAaveTokenV3
  );

  // deploy migration payloads
  const shortMigrationPayload = await deployShortPermissionsPayload(
    walletClient,
    publicClient,
    DEPLOYER
  );
  const longMigrationPayload = await deployLongPermissionsPayload(
    walletClient,
    publicClient,
    DEPLOYER
  );

  // create proposal on v2
  const shortProposalId = await createV2Proposal(
    walletClient,
    publicClient,
    [aAaveTokenPayload, shortMigrationPayload],
    AaveGovernanceV2.SHORT_EXECUTOR
  );
  const longProposalId = await createV2Proposal(
    walletClient,
    publicClient,
    [stkAaveTokenPayload, aaveTokenPayload, longMigrationPayload],
    AaveGovernanceV2.LONG_EXECUTOR
  );

  // change owner
  await changeExecutorsOwner(
    AaveGovernanceV2.SHORT_EXECUTOR,
    GovernanceV3Ethereum.EXECUTOR_LVL_1,
    publicClient,
    walletClient
  );
  await changeExecutorsOwner(
    AaveGovernanceV2.LONG_EXECUTOR,
    GovernanceV3Ethereum.EXECUTOR_LVL_2,
    publicClient,
    walletClient
  );

  // execute proposals
  await executeV2Proposals(shortProposalId, longProposalId, walletClient, publicClient, fork);

  // deploy new voting machine
  const votingMachine = await deployVotingMachine(DEPLOYER, publicClient, walletClient);
  // deploy new voting portal
  const votingPortal = await deployVotingPortal(
    votingMachine,
    DEPLOYER,
    publicClient,
    walletClient
  );

  // deploy and register new payload
  // create proposal on gov v3
  // execute proposal on v3
};

deployPayloadsV2().then().catch(console.log);
