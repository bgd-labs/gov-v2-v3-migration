import 'dotenv/config';
import {tenderly} from '@bgd-labs/aave-cli';
import path from 'path';
import {Address, createPublicClient, createWalletClient, http} from 'viem';
import {arbitrum, avalanche, base, mainnet, metis, optimism, polygon} from 'viem/chains';
import {
  deployAAaveImpl,
  deployAAaveTokenPayload,
  deployAaveImpl,
  deployAaveTokenPayload,
  deployStkAaveImpl,
  deployStkAaveTokenPayload,
  executeL2Payload,
} from './payloadsV2';
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
  GovernanceV3Metis,
} from '@bgd-labs/aave-address-book';
import {
  changeExecutorsOwner,
  deployAndRegisterTestPayloads,
  deployVotingMachine,
  deployVotingPortal,
  generateProposalAndExecutePayload,
  Payload,
} from './proposalsV3';
import PolygonMovePermissionsPayload from '../out/PolygonMovePermissionsPayload.sol/PolygonMovePermissionsPayload.json';
import AvaxMovePermissionsPayload from '../out/AvaxMovePermissionsPayload.sol/AvaxMovePermissionsPayload.json';
import ArbMovePermissionsPayload from '../out/ArbMovePermissionsPayload.sol/ArbMovePermissionsPayload.json';
import BaseMovePermissionsPayload from '../out/BaseMovePermissionsPayload.sol/BaseMovePermissionsPayload.json';
import MetisMovePermissionsPayload from '../out/MetisMovePermissionsPayload.sol/MetisMovePermissionsPayload.json';
import OptMovePermissionsPayload from '../out/OptMovePermissionsPayload.sol/OptMovePermissionsPayload.json';
import TestV2PayloadEthereum from '../out/PoolPayload.sol/TestV2PayloadEthereum.json';
import TestV3PayloadEthereum from '../out/PoolPayload.sol/TestV3PayloadEthereum.json';
import TestV2PayloadPolygon from '../out/PoolPayload.sol/TestV2PayloadPolygon.json';
import TestV3PayloadPolygon from '../out/PoolPayload.sol/TestV3PayloadPolygon.json';
import TestV2PayloadAvalanche from '../out/PoolPayload.sol/TestV2PayloadAvalanche.json';
import TestV3PayloadAvalanche from '../out/PoolPayload.sol/TestV3PayloadAvalanche.json';
import TestV3PayloadArbitrum from '../out/PoolPayload.sol/TestV3PayloadArbitrum.json';
import TestV3PayloadOptimism from '../out/PoolPayload.sol/TestV3PayloadOptimism.json';
import TestV3PayloadBase from '../out/PoolPayload.sol/TestV3PayloadBase.json';
import TestV3PayloadMetis from '../out/PoolPayload.sol/TestV3PayloadMetis.json';
import {deployContract} from './helpers';
import EthShortMovePermissionsPayload from '../out/EthShortMovePermissionsPayload.sol/EthShortMovePermissionsPayload.json';
import EthLongMovePermissionsPayload from '../out/EthLongMovePermissionsPayload.sol/EthLongMovePermissionsPayload.json';

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
  artifact: any,
  governanceAddresses: any,
  payloadArtifacts: any[]
) => {
  const {fork, walletClient, publicClient} = await getFork(chain);

  const payload = await deployContract(walletClient, publicClient, DEPLOYER, artifact);

  await executeL2Payload(walletClient, publicClient, executor, payload, artifact.abi);

  const payloadId = await deployAndRegisterTestPayloads(
    walletClient,
    publicClient,
    DEPLOYER,
    governanceAddresses,
    payloadArtifacts
  );

  const payloads: Payload[] = [];
  payloads.push({
    payloadsController: GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
    chain: chain.id,
    payloadId: payloadId,
    accessLevel: 1,
  });
  const {
    fork: mainnetFork,
    walletClient: mainnetWalletClient,
    publicClient: mainnetPublicClient,
  } = await getFork(mainnet);

  await generateProposalAndExecutePayload(
    mainnetWalletClient,
    mainnetPublicClient,
    mainnetFork,
    AaveMisc.ECOSYSTEM_RESERVE,
    payloadId,
    chain
  );
};

const deployPayloadsEthereum = async () => {
  const {fork, walletClient, publicClient} = await getFork(mainnet);

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
  const shortMigrationPayload = await deployContract(
    walletClient,
    publicClient,
    DEPLOYER,
    EthShortMovePermissionsPayload
  );
  const longMigrationPayload = await deployContract(
    walletClient,
    publicClient,
    DEPLOYER,
    EthLongMovePermissionsPayload
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

  // execute proposals
  await executeV2Proposals(shortProposalId, longProposalId, walletClient, publicClient, fork);

  const payloadId = await deployAndRegisterTestPayloads(
    walletClient,
    publicClient,
    DEPLOYER,
    GovernanceV3Ethereum,
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

deployAndExecuteL2Payload(
  polygon,
  AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR,
  PolygonMovePermissionsPayload,
  GovernanceV3Polygon,
  [TestV2PayloadPolygon, TestV3PayloadPolygon]
)
  .then()
  .catch(console.log);

deployAndExecuteL2Payload(
  avalanche,
  AVAX_GUARDIAN,
  AvaxMovePermissionsPayload,
  GovernanceV3Avalanche,
  [TestV2PayloadAvalanche, TestV3PayloadAvalanche]
)
  .then()
  .catch(console.log);

deployAndExecuteL2Payload(
  arbitrum,
  AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR,
  ArbMovePermissionsPayload,
  GovernanceV3Arbitrum,
  [TestV3PayloadArbitrum]
)
  .then()
  .catch(console.log);

deployAndExecuteL2Payload(
  optimism,
  AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR,
  OptMovePermissionsPayload,
  GovernanceV3Optimism,
  [TestV3PayloadOptimism]
)
  .then()
  .catch(console.log);

deployAndExecuteL2Payload(
  base,
  AaveGovernanceV2.BASE_BRIDGE_EXECUTOR,
  BaseMovePermissionsPayload,
  GovernanceV3Base,
  [TestV3PayloadBase]
)
  .then()
  .catch(console.log);

deployAndExecuteL2Payload(
  metis,
  AaveGovernanceV2.METIS_BRIDGE_EXECUTOR,
  MetisMovePermissionsPayload,
  GovernanceV3Metis,
  [TestV3PayloadMetis]
)
  .then()
  .catch(console.log);
