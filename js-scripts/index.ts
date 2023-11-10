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
import TestV2PayloadEthereum from '../out/PoolPayload.sol/TestV2PayloadEthereum.json';
import TestV3PayloadEthereum from '../out/PoolPayload.sol/TestV3PayloadEthereum.json';
import TestV2PayloadPolygon from '../out/PoolPayload.sol/TestV2PayloadPolygon.json';
import TestV3PayloadPolygon from '../out/PoolPayload.sol/TestV3PayloadPolygon.json';
import TestV2PayloadAvalanche from '../out/PoolPayload.sol/TestV2PayloadAvalanche.json';
import TestV3PayloadAvalanche from '../out/PoolPayload.sol/TestV3PayloadAvalanche.json';
import TestV3PayloadArbitrum from '../out/PoolPayload.sol/TestV3PayloadArbitrum.json';
import TestV3PayloadOptimism from '../out/PoolPayload.sol/TestV3PayloadOptimism.json';
import TestV3PayloadBase from '../out/PoolPayload.sol/TestV3PayloadBase.json';
import TestV2_5PayloadEthereum from '../out/PoolPayload.sol/TestV2_5PayloadEthereum.json';
import {createAndExecuteGovernanceV3Payload} from './payloadsV3';
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
    fork = await tenderly.getForkInfo(forkIdByNetwork[chain.id]);
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

const getForkInfo = async () => {
  // rpc.tenderly.co/fork/5b6e4a5b-96c7-47c1-9103-52ee1c17bc88
  const response = await fetch(
    'https://api.tenderly.co/api/v1/account/bgd-labs/project/governance-v3/fork/5b6e4a5b-96c7-47c1-9103-52ee1c17bc88',
    {
      method: 'GET',
      headers: new Headers({
        'Content-Type': 'application/json',
        'X-Access-Key': 'MgtjFl-q99PY32WbxMRl8K119euRkTcd',
      }),
    }
  );
  const result = await response.json();
  console.log('--------> ', result);
};

getForkInfo().then().catch();

const deployAndExecuteL2Payload = async (
  chain: any,
  executor: Address,
  payloadAddress: any,
  governanceAddresses: any,
  payloadArtifacts: any[]
) => {
  const {fork, walletClient, publicClient} = await getFork(chain);

  if (chain.id !== avalanche.id) {
    await executeL2Payload(walletClient, publicClient, executor, payloadAddress, fork);
  } else {
    await executeL2PayloadViaGuardian(walletClient, publicClient, executor, payloadAddress, fork);
  }
  await createAndExecuteGovernanceV3Payload(
    governanceAddresses.PAYLOADS_CONTROLLER,
    publicClient,
    walletClient,
    fork,
    payloadArtifacts
  );
};

const deployPayloadsEthereum = async () => {
  const {fork, walletClient, publicClient} = await getFork(mainnet);

  const shortMigrationPayload = '0xe40e84457f4b5075f1eb32352d81ecf1de77fee6';
  // const longMigrationPayload = '0x6195a956dC026A949dE552F04a5803d3aa1fC408';

  const block = await publicClient.getBlock();
  // create proposal on v2
  // const longProposalId = await createV2Proposal(
  //   walletClient,
  //   publicClient,
  //   [longMigrationPayload],
  //   AaveGovernanceV2.LONG_EXECUTOR
  // );
  //
  const timeToWarpTo = block.timestamp; // + 60n * 60n * 24n * 16n;
  //
  // await tenderly.warpTime(fork, timeToWarpTo);

  const shortProposalId = await createV2Proposal(
    walletClient,
    publicClient,
    [shortMigrationPayload],
    AaveGovernanceV2.SHORT_EXECUTOR
  );

  // execute proposals
  // await executeV2Proposals(shortProposalId, longProposalId, walletClient, publicClient, fork, {
  //   number: block.number,
  //   timestamp: timeToWarpTo,
  // });

  await executeV2Proposal(shortProposalId, walletClient, publicClient, fork, {
    number: block.number,
    timestamp: timeToWarpTo,
  });

  const payloadId = await deployAndRegisterTestPayloads(
    walletClient,
    publicClient,
    DEPLOYER,
    GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
    [TestV2PayloadEthereum, TestV3PayloadEthereum]
  );

  // deploy payload 2.5
  const payload_2_5 = await deployContract(
    walletClient,
    publicClient,
    DEPLOYER,
    TestV2_5PayloadEthereum
  );

  // create proposal 2.5
  const shortProposal2_5Id = await createV2Proposal(
    walletClient,
    publicClient,
    [payload_2_5],
    AaveGovernanceV2.SHORT_EXECUTOR
  );

  // execute proposal 2.5
  const block2_5 = await publicClient.getBlock();
  await executeV2Proposal(shortProposal2_5Id, walletClient, publicClient, fork, {
    number: block2_5.number,
    timestamp: block2_5.timestamp,
  });

  // const proposalId = await generateProposalAndExecutePayload(
  //   walletClient,
  //   publicClient,
  //   fork,
  //   AaveMisc.ECOSYSTEM_RESERVE,
  //   payloadId,
  //   mainnet
  // );
  // console.log('proposalId: ', proposalId);
};

// deployPayloadsEthereum().then().catch(console.log);

async function upgradeL2s() {
  await deployAndExecuteL2Payload(
    polygon,
    AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR,
    '0xc7751400f809cdb0c167f87985083c558a0610f7',
    GovernanceV3Polygon,
    [TestV2PayloadPolygon, TestV3PayloadPolygon]
  );

  await deployAndExecuteL2Payload(
    avalanche,
    AVAX_GUARDIAN,
    '0x0a5a19f1c4a527773f8b6e7428255dd83b7a687b',
    GovernanceV3Avalanche,
    [TestV2PayloadAvalanche, TestV3PayloadAvalanche]
  );

  await deployAndExecuteL2Payload(
    arbitrum,
    AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR,
    '0xd0f0bc55ac46f63a68f7c27fbfd60792c9571fea',
    GovernanceV3Arbitrum,
    [TestV3PayloadArbitrum]
  );

  await deployAndExecuteL2Payload(
    optimism,
    AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR,
    '0xab22988d93d5f942fc6b6c6ea285744809d1d9cc',
    GovernanceV3Optimism,
    [TestV3PayloadOptimism]
  );

  await deployAndExecuteL2Payload(
    base,
    AaveGovernanceV2.BASE_BRIDGE_EXECUTOR,
    '0x80a2f9a653d3990878cff8206588fd66699e7f2a',
    GovernanceV3Base,
    [TestV3PayloadBase]
  );
}

// upgradeL2s();
