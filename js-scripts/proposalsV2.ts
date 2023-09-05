import {AaveGovernanceV2, AaveMisc, IAaveGovernanceV2_ABI} from '@bgd-labs/aave-address-book';
import {
  Address,
  concat,
  encodeAbiParameters,
  encodeFunctionData,
  fromHex,
  getContract,
  Hex,
  keccak256,
  pad,
  parseAbiParameters,
  parseEther,
  PublicClient,
  toHex,
  WalletClient,
} from 'viem';
import {tenderly} from '@bgd-labs/aave-cli';
import {EOA, getAaveGovernanceV2Slots, getSolidityStorageSlotBytes} from './helpers';
import {EXECUTOR_ABI} from './abis/V2ExecutorAbi';

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

const simulateOnTenderly = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  proposalId: bigint
) => {
  const aaveGovernanceV2Contract = getContract({
    address: AaveGovernanceV2.GOV,
    abi: IAaveGovernanceV2_ABI,
    publicClient,
  });
  const proposal = await aaveGovernanceV2Contract.read.getProposalById([proposalId]);

  const slots = getAaveGovernanceV2Slots(proposalId, proposal.executor);
  const executorContract = getContract({
    address: proposal.executor,
    abi: EXECUTOR_ABI,
    publicClient,
  });
  const duration = await executorContract.read.VOTING_DURATION();
  const delay = await executorContract.read.getDelay();

  /**
   * For proposals that are still pending it might happen that the startBlock is not mined yet.
   * Therefor in this case we need to estimate the startTimestamp.
   */
  const latestBlock = await publicClient.getBlock();
  const isStartBlockMinted = latestBlock.number! < proposal.startBlock;
  const startTimestamp = isStartBlockMinted
    ? latestBlock.timestamp + (proposal.startBlock - latestBlock.number!) * 12n
    : (await publicClient.getBlock({blockNumber: proposal.startBlock})).timestamp;

  const endBlockNumber = proposal.startBlock + (duration as bigint) + 2n;
  const isEndBlockMinted = latestBlock.number! > endBlockNumber;

  // construct the earliest possible header for execution
  const blockHeader = {
    timestamp: toHex(startTimestamp + ((duration as bigint) + 1n) * 12n + (delay as bigint) + 1n),
    number: toHex(endBlockNumber),
  };

  return {
    network_id: String(publicClient.chain?.id),
    block_number: Number(isEndBlockMinted ? endBlockNumber : latestBlock.number),
    from: EOA,
    to: AaveGovernanceV2.GOV,
    gas_price: '0',
    value: proposal.values.reduce((sum, cur) => sum + cur).toString(),
    gas: 30_000_000,
    input: encodeFunctionData({
      abi: IAaveGovernanceV2_ABI,
      functionName: 'execute',
      args: [proposalId],
    }),
    block_header: blockHeader,
    state_objects: {
      // Give `from` address 10 ETH to send transaction
      [EOA]: {balance: parseEther('10').toString()},
      // Ensure transactions are queued in the executor
      [proposal.executor]: {
        storage: proposal.targets.reduce((acc, target, i) => {
          const hash = keccak256(
            encodeAbiParameters(
              parseAbiParameters('address, uint256, string, bytes, uint256, bool'),
              [
                target,
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                fromHex(blockHeader.timestamp, 'bigint'),
                proposal.withDelegatecalls[i],
              ]
            )
          );
          const slot = getSolidityStorageSlotBytes(slots.queuedTxsSlot, hash);
          acc[slot] = pad('0x1', {size: 32});
          return acc;
        }, {} as any),
      },
      [AaveGovernanceV2.GOV]: {
        storage: {
          [slots.eta]: pad(blockHeader.timestamp, {size: 32}),
          [slots.forVotes]: pad(toHex(parseEther('3000000')), {size: 32}),
          [slots.againstVotes]: pad('0x0', {size: 32}),
          [slots.canceled]: pad(concat([AaveGovernanceV2.GOV_STRATEGY, '0x0000']), {size: 32}),
        },
      },
    },
  };
};

// execute proposals
export const executeV2Proposals = async (
  shortProposalId: bigint,
  longProposalId: bigint,
  walletClient: WalletClient,
  publicClient: PublicClient,
  fork: any
) => {
  const shortProposalObject = await simulateOnTenderly(publicClient, walletClient, shortProposalId);
  const longProposalObject = await simulateOnTenderly(publicClient, walletClient, longProposalId);

  await tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, shortProposalObject);
  await tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, longProposalObject);
};
