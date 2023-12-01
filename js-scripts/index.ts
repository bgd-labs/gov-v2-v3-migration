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
import {ArcTimelock_ABI} from './abis/ArcTimelock';

export const DEPLOYER = '0xEAF6183bAb3eFD3bF856Ac5C058431C8592394d6';
export const AVAX_GUARDIAN = '0xa35b76E4935449E33C56aB24b23fcd3246f13470';
// create mainnet fork

const forkIdByNetwork: Record<number, string> = {
  1: '3625066b-2d1b-49b0-acb3-4fe22cc391eb',
  137: '055d96d7-7612-41a4-aa39-fdedad2a3ba4',
  43_114: 'e323cdc4-0414-4572-8e8c-1311615881ba',
  8453: 'a92f8e60-6a6d-440a-9067-0d8535fea8b2',
};

const getFork = async (chain: any, fixed?: boolean) => {
  let fork: any;
  if (!fixed && process.env.TENDERLY_PROJECT_SLUG) {
    fork = await tenderly.getForkInfo(forkIdByNetwork[chain.id], 'governance-v3');
  } else {
    fork = await tenderly.fork({chainId: chain.id, alias: 'migration', forkChainId: chain.id});
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

const deployAndExecuteOldL2Payload = async (chain: any, executor: Address, payloadAddress: any) => {
  const {fork, walletClient, publicClient} = await getFork(chain);

  await executeL2Payload(walletClient, publicClient, executor, payloadAddress, fork);
};

const deployPayloadsEthereum = async () => {
  const {fork, walletClient, publicClient} = await getFork(mainnet);

  const shortMigrationPayload = '0x30dB87b980D42C060ED90fc890b3b64a24EF41c5';
  const longMigrationPayload = '0xF60BDDE9077Be3226Db8109432d78afD92a8A003';

  const block = await publicClient.getBlock();
  // create proposal on v2
  const longProposalId = await createV2Proposal(
    walletClient,
    publicClient,
    [longMigrationPayload],
    AaveGovernanceV2.LONG_EXECUTOR
  );

  const timeToWarpTo = block.timestamp + 60n * 60n * 24n * 14n;
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

  // execute lvl1
  await deployAndExecuteL2Payload(mainnet, 16, GovernanceV3Ethereum);

  // execute aave arc
  const block2 = await publicClient.getBlock();
  const timeToWarpToLvl1 = block2.timestamp + 60n * 60n * 24n * 2n + 60n;
  await tenderly.warpTime(fork, timeToWarpToLvl1);

  const {request, result} = await publicClient.simulateContract({
    address: AaveGovernanceV2.ARC_TIMELOCK,
    abi: ArcTimelock_ABI,
    functionName: 'execute',
    account: DEPLOYER,
    args: [5],
  });
  const hash = await walletClient.writeContract(request);
};

async function upgradeL2s() {
  await deployAndExecuteL2Payload(polygon, 10, GovernanceV3Polygon);
  await deployAndExecuteL2Payload(avalanche, 7, GovernanceV3Avalanche);

  // execute base with old executor
  await deployAndExecuteOldL2Payload(
    base,
    AaveGovernanceV2.BASE_BRIDGE_EXECUTOR,
    '0x2e649f6b54B07E210b31c9cC2eB8a0d5997c3D4A'
  );
}

const generateForks = async () => {
  const mainnetFork = await getFork(mainnet, true);
  // const polFork = await getFork(polygon, true);
  // const avaFork = await getFork(avalanche, true);
  // const baseFork = await getFork(base, true);
};

// generateForks();
// upgradeL2s();
// deployPayloadsEthereum().then().catch(console.log);
