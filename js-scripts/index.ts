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
  1: '669e1b6f-00e9-4bb2-a217-4b4b66e13f8d',
  137: '43d79c07-30f3-4001-af68-ca4c466651a4',
  43_114: '816c495a-864e-49b2-b1b7-89688ecadd95',
  8453: 'c0075b05-3600-456b-864a-d4e3a6c0d9ab',
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
  console.log(fork);
  await executeGovernanceV3Payload(
    governanceAddresses.PAYLOADS_CONTROLLER,
    publicClient,
    payloadId,
    fork
  );
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
  const timeToWarpToLvl1 = block.timestamp + 60n * 60n * 24n * 2n;
  await tenderly.warpTime(fork, timeToWarpToLvl1);
  await deployAndExecuteL2Payload(mainnet, 13, GovernanceV3Ethereum);

  // TODO: execute aave arc
};

deployPayloadsEthereum().then().catch(console.log);

async function upgradeL2s() {
  await deployAndExecuteL2Payload(polygon, 8, GovernanceV3Polygon);
  await deployAndExecuteL2Payload(avalanche, 5, GovernanceV3Avalanche);

  // TODO: execute base
}

const generateForks = async () => {
  const mainnetFork = await getFork(mainnet, true);
  const polFork = await getFork(polygon, true);
  const avaFork = await getFork(avalanche, true);
  const baseFork = await getFork(base, true);
};
// generateForks();
// upgradeL2s();
