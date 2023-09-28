import {getPayloadsController, tenderly} from '@bgd-labs/aave-cli';
import {Hex, PublicClient, WalletClient} from 'viem';
import {deployAndRegisterTestPayloads} from './proposalsV3';
import {DEPLOYER} from '.';

export async function createAndExecuteGovernanceV3Payload(
  controller: Hex,
  publicClient: PublicClient,
  walletClient: WalletClient,
  fork: any,
  artifacts: any[]
) {
  const payloadsController = getPayloadsController(controller, publicClient);
  const payloadId = await deployAndRegisterTestPayloads(
    walletClient,
    publicClient,
    DEPLOYER,
    controller,
    artifacts
  );
  const tenderlyRequest = await payloadsController.getSimulationPayloadForExecution(payloadId);
  return tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, tenderlyRequest);
}
