import 'dotenv/config';
import {tenderly} from '@bgd-labs/aave-cli';
import {Address, createPublicClient, createWalletClient, http} from 'viem';
import {arbitrum, avalanche, base, mainnet, optimism, polygon} from 'viem/chains';
import {executeL2Payload, executeL2PayloadViaGuardian} from './payloadsV2';
import {createV2Proposal, executeV2Proposal, executeV2Proposals} from './proposalsV2';
import {
  AaveGovernanceV2,
  GovernanceV3Ethereum,
  AaveMisc,
  GovernanceV3Polygon,
  GovernanceV3Avalanche,
  GovernanceV3Arbitrum,
  GovernanceV3Optimism,
  GovernanceV3Base,
} from '@bgd-labs/aave-address-book';
import {deployAndRegisterTestPayloads, generateProposalAndExecutePayload} from './proposalsV3';
import {createAndExecuteGovernanceV3Payload, executeGovernanceV3Payload} from './payloadsV3';
import {deployContract} from './helpers';

export const DEPLOYER = '0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6';
export const AVAX_GUARDIAN = '0xa35b76E4935449E33C56aB24b23fcd3246f13470';
// create mainnet fork

const forkIdByNetwork: Record<number, string> = {
  1: 'e9279f2c-8033-4a28-b9b8-4465fe50ffbc',
  137: 'a65ea772-1ccb-48b6-8c0b-9fabb3dc07e2',
  43_114: 'e57f9ba6-2357-4963-a2a3-7cf66cd4f1d3',
  8453: '7b18548c-aeff-4013-af55-c4508f14dcdf',
  42_161: '2883e0f6-ccb4-46a9-a3f3-79ef521fa5b3',
  10: '79632950-d543-4b7c-b5eb-2beda6ba5738',
};

const getFork = async (chain: any, fixed?: boolean) => {
  let fork: any;
  if (!fixed && process.env.TENDERLY_PROJECT_SLUG) {
    console.log('------', forkIdByNetwork[chain.id]);
    fork = await tenderly.getForkInfo(forkIdByNetwork[chain.id], 'governance-v3');
    console.log('fork', fork);
  } else {
    fork = await tenderly.fork({chainId: chain.id, alias: 'govV3Fork'});
  }

  const walletClient = createWalletClient({
    account: AaveMisc.ECOSYSTEM_RESERVE,
    chain: {...chain, id: fork.forkNetworkId, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  const publicClient = createPublicClient({
    chain: {...chain, id: fork.forkNetworkId, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  return {fork, walletClient, publicClient};
};

const deployAndExecuteL2Payload = async (
  chain: any,
  payloadId: number,
  governanceAddresses: any
) => {
  const {fork, walletClient, publicClient} = await getFork(chain);

  await executeGovernanceV3Payload(
    governanceAddresses.PAYLOADS_CONTROLLER,
    publicClient,
    payloadId,
    fork
  );
};

const deployPayloadsEthereum = async () => {
  const {fork, walletClient, publicClient} = await getFork(mainnet);

  const shortMigrationPayload = '0xe40e84457f4b5075f1eb32352d81ecf1de77fee6';
  const longMigrationPayload = '0x6195a956dC026A949dE552F04a5803d3aa1fC408';

  const block = await publicClient.getBlock();
  // create proposal on v2
  const longProposalId = await createV2Proposal(
    walletClient,
    publicClient,
    [longMigrationPayload],
    AaveGovernanceV2.LONG_EXECUTOR
  );

  const timeToWarpTo = block.timestamp + 60n * 60n * 24n * 16n;
  await tenderly.warpTime(fork, timeToWarpTo);

  const shortProposalId = await createV2Proposal(
    walletClient,
    publicClient,
    [shortMigrationPayload],
    AaveGovernanceV2.SHORT_EXECUTOR
  );

  // execute proposals
  await executeV2Proposals(shortProposalId, longProposalId, walletClient, publicClient, fork, {
    number: block.number,
    timestamp: timeToWarpTo,
  });

  // TODO: execute aave arc
};

// deployPayloadsEthereum().then().catch(console.log);

async function upgradeL2s() {
  await deployAndExecuteL2Payload(mainnet, 12, GovernanceV3Ethereum);
  await deployAndExecuteL2Payload(polygon, 5, GovernanceV3Polygon);
  await deployAndExecuteL2Payload(avalanche, 4, GovernanceV3Avalanche);

  // TODO: execute base
}

upgradeL2s();
