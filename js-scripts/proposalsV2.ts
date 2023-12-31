import {
  AaveGovernanceV2,
  AaveMisc,
  AaveV3Ethereum,
  IAaveGovernanceV2_ABI,
} from '@bgd-labs/aave-address-book';
import {Address, Hex, PublicClient, WalletClient} from 'viem';
import {tenderly} from '@bgd-labs/aave-cli';
import {simulateOnTenderly} from './helpers';

// create proposals
export const createV2Proposal = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  targetAddresses: Address[],
  executor: Address
) => {
  const targets: Hex[] = [];
  const values: bigint[] = [];
  const signatures: string[] = [];
  const calldatas: Hex[] = [];
  const withDelegateCalls: boolean[] = [];

  for (let i = 0; i < targetAddresses.length; i++) {
    targets[i] = targetAddresses[i];
    values[i] = BigInt(0);
    signatures[i] = 'execute()';
    calldatas[i] = '0x';
    withDelegateCalls[i] = true;
  }

  const {request, result} = await publicClient.simulateContract({
    address: AaveGovernanceV2.GOV,
    abi: IAaveGovernanceV2_ABI,
    functionName: 'create',
    args: [
      executor,
      targets,
      values,
      signatures,
      calldatas,
      withDelegateCalls,
      '0x22f22ad910127d3ca76dc642f94db34397f94ca969485a216b9d82387808cdfa' as Hex, //ipfsHash,
    ],
    account: AaveMisc.ECOSYSTEM_RESERVE,
  });
  const hash = await walletClient.writeContract(request);
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  // console.log('txproposal: ', transaction);
  return result;
};

// execute proposals
export const executeV2Proposals = async (
  shortProposalId: bigint,
  longProposalId: bigint,
  walletClient: WalletClient,
  publicClient: PublicClient,
  fork: any,
  latestBlock: {number: bigint; timestamp: bigint}
) => {
  const longProposalObject = await simulateOnTenderly(
    publicClient,
    walletClient,
    longProposalId,
    latestBlock
  );
  const shortProposalObject = await simulateOnTenderly(
    publicClient,
    walletClient,
    shortProposalId,
    {...latestBlock, number: latestBlock.number + 1n}
  );
  const longHash = await tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, longProposalObject);

  const shortHash = await tenderly.unwrapAndExecuteSimulationPayloadOnFork(
    fork,
    shortProposalObject
  );
};

export const executeV2Proposal = async (
  proposalId: bigint,
  walletClient: WalletClient,
  publicClient: PublicClient,
  fork: any,
  latestBlock: {number: bigint; timestamp: bigint}
) => {
  const proposalObject = await simulateOnTenderly(publicClient, walletClient, proposalId, {
    ...latestBlock,
    number: latestBlock.number + 1n,
  });

  const proposalHash = await tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, proposalObject);
};
