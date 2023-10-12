import 'dotenv/config';
import {tenderly} from '@bgd-labs/aave-cli';
import {Address, createPublicClient, createWalletClient, http} from 'viem';
import {arbitrum, avalanche, base, mainnet, optimism, polygon} from 'viem/chains';
import {executeL2Payload, executeL2PayloadViaGuardian} from './payloadsV2';
import {createV2Proposal, executeV2Proposals} from './proposalsV2';
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
import {createAndExecuteGovernanceV3Payload} from './payloadsV3';

export const DEPLOYER = '0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6';
export const AVAX_GUARDIAN = '0xa35b76E4935449E33C56aB24b23fcd3246f13470';
// create mainnet fork
const getFork = async (chain: any) => {
  const fork = await tenderly.fork({chainId: chain.id, alias: 'govV3Fork'});

  const walletClient = createWalletClient({
    account: AaveMisc.ECOSYSTEM_RESERVE,
    chain: {...chain, id: 3030, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  const publicClient = createPublicClient({
    chain: {...chain, id: 3030, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  return {fork, walletClient, publicClient};
};

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

  const shortMigrationPayload = '0x7fC3ebdB376fF38De2cD597671A6270113c27364';
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

  const payloadId = await deployAndRegisterTestPayloads(
    walletClient,
    publicClient,
    DEPLOYER,
    GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
    [TestV2PayloadEthereum, TestV3PayloadEthereum]
  );
  const proposalId = await generateProposalAndExecutePayload(
    walletClient,
    publicClient,
    fork,
    AaveMisc.ECOSYSTEM_RESERVE,
    payloadId,
    mainnet
  );
  console.log('proposalId: ', proposalId);
};

deployPayloadsEthereum().then().catch(console.log);

async function upgradeL2s() {
  await deployAndExecuteL2Payload(
    polygon,
    AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR,
    '0x274a46efd4364ccba654dc74ddb793f9010b179c',
    GovernanceV3Polygon,
    [TestV2PayloadPolygon, TestV3PayloadPolygon]
  );

  await deployAndExecuteL2Payload(
    avalanche,
    AVAX_GUARDIAN,
    '0xb58e840e1356ed9b7f89d11a03d4cef24f56a1ea',
    GovernanceV3Avalanche,
    [TestV2PayloadAvalanche, TestV3PayloadAvalanche]
  );

  await deployAndExecuteL2Payload(
    arbitrum,
    AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR,
    '0xfd858c8bc5ac5e10f01018bc78471bb0dc392247',
    GovernanceV3Arbitrum,
    [TestV3PayloadArbitrum]
  );

  await deployAndExecuteL2Payload(
    optimism,
    AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR,
    '0x7fc3fcb14ef04a48bb0c12f0c39cd74c249c37d8',
    GovernanceV3Optimism,
    [TestV3PayloadOptimism]
  );

  await deployAndExecuteL2Payload(
    base,
    AaveGovernanceV2.BASE_BRIDGE_EXECUTOR,
    '0x4959bad86d851378c6bccf07cb8240d55a11c5ac',
    GovernanceV3Base,
    [TestV3PayloadBase]
  );
}

upgradeL2s();
