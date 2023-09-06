import {
  Address,
  concat,
  encodeAbiParameters,
  encodeFunctionData,
  encodePacked,
  fromHex,
  getContract,
  Hex,
  keccak256,
  pad,
  parseAbiParameters,
  parseEther,
  PublicClient,
  toHex,
  trim,
  WalletClient,
} from 'viem';
import {
  AaveGovernanceV2,
  IAaveGovernanceV2_ABI,
  IExecutorWithTimelock_ABI,
  IPayloadsControllerCore_ABI,
} from '@bgd-labs/aave-address-book';
import {TenderlyRequest} from '@bgd-labs/aave-cli/src/utils/tenderlyClient';
import {PayloadState} from '@bgd-labs/aave-cli/src/simulate/govv3/payloadsController';

export const EOA = '0xD73a92Be73EfbFcF3854433A5FcbAbF9c1316073' as const;

export const AAVE_GOVERNANCE_V2_START_BLOCK = 11427398n;

/**
 * @notice Returns the storage slot for a Solidity mapping with bytes32 keys, given the slot of the mapping itself
 * @dev Read more at https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#mappings-and-dynamic-arrays
 * @param mappingSlot Mapping slot in storage
 * @param key Mapping key to find slot for
 * @returns Storage slot
 */
export const getSolidityStorageSlotBytes = (mappingSlot: Hex, key: Hex) => {
  const slot = pad(mappingSlot, {size: 32});
  return trim(
    keccak256(encodeAbiParameters(parseAbiParameters('bytes32, uint256'), [key, BigInt(slot)]))
  );
};

/**
 * @notice Returns the storage slot for a Solidity mapping with uint keys, given the slot of the mapping itself
 * @dev Read more at https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#mappings-and-dynamic-arrays
 * @param mappingSlot Mapping slot in storage
 * @param key Mapping key to find slot for
 * @returns Storage slot
 */
export const getSolidityStorageSlotUint = (mappingSlot: bigint, key: bigint) => {
  // this will also work for address types, since address and uints are encoded the same way
  // const slot = pad(mappingSlot, { size: 32 });
  return keccak256(encodeAbiParameters(parseAbiParameters('uint256, uint256'), [key, mappingSlot]));
};

/**
 * @notice Returns an object containing various AaveGovernanceV2 slots
 * @param id Proposal ID
 */
export const getAaveGovernanceV2Slots = (proposalId: bigint, executor: Address) => {
  // TODO generalize this for other storage layouts

  // struct Proposal {
  //   uint256 id;
  //   address creator;
  //   IExecutorWithTimelock executor;
  //   address[] targets;
  //   uint256[] values;
  //   string[] signatures;
  //   bytes[] calldatas;
  //   bool[] withDelegatecalls;
  //   uint256 startBlock;
  //   uint256 endBlock;
  //   uint256 executionTime;
  //   uint256 forVotes;
  //   uint256 againstVotes;
  //   bool executed;
  //   bool canceled;
  //   address strategy;
  //   bytes32 ipfsHash;
  //   mapping(address => Vote) votes;
  // }

  const etaOffset = 10n;
  const forVotesOffset = 11n;
  const againstVotesOffset = 12n;
  const canceledSlotOffset = 13n; // this is packed with `executed`

  // Compute and return slot numbers
  const votingStrategySlot: Hex = '0x1';
  let queuedTxsSlot: Hex;
  if (executor === AaveGovernanceV2.SHORT_EXECUTOR) {
    queuedTxsSlot = '0x3';
  }
  if (executor === AaveGovernanceV2.LONG_EXECUTOR) {
    queuedTxsSlot = '0x07';
  }
  if (!queuedTxsSlot!) throw new Error('unknown executor');
  const proposalsMapSlot = 4n; // proposals ID to proposal struct mapping
  const proposalSlot = fromHex(getSolidityStorageSlotUint(proposalsMapSlot, proposalId), 'bigint');
  return {
    queuedTxsSlot,
    votingStrategySlot,
    proposalsMapSlot: proposalsMapSlot,
    proposalSlot: proposalSlot,
    canceled: pad(toHex(proposalSlot + canceledSlotOffset), {size: 32}),
    eta: pad(toHex(proposalSlot + etaOffset), {size: 32}),
    forVotes: pad(toHex(proposalSlot + forVotesOffset), {size: 32}),
    againstVotes: pad(toHex(proposalSlot + againstVotesOffset), {size: 32}),
  };
};

export const simulateOnTenderly = async (
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
    abi: IExecutorWithTimelock_ABI,
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

const getSimulationPayloadForExecution = async (
  id: number,
  payloadsController: Address,
  publicClient: PublicClient
) => {
  const controllerContract = getContract({
    abi: IPayloadsControllerCore_ABI,
    address: payloadsController,
    publicClient,
  });

  const payload = await controllerContract.read.getPayloadById([id]);
  const _currentBlock = await publicClient.getBlockNumber();
  // workaround for tenderly lags & bugs when not specifying the blocknumber
  const currentBlock = await publicClient.getBlock({blockNumber: _currentBlock - 5n});
  const simulationPayload: TenderlyRequest = {
    network_id: String(publicClient.chain!.id),
    from: EOA,
    to: controllerContract.address,
    input: encodeFunctionData({
      abi: IPayloadsControllerCore_ABI,
      functionName: 'executePayload',
      args: [id],
    }),
    block_number: Number(currentBlock.number),
    state_objects: {
      [controllerContract.address]: {
        storage: {
          [getSolidityStorageSlotUint(3n, BigInt(id))]: encodePacked(
            ['uint40', 'uint40', 'uint8', 'uint8', 'address'],
            [
              Number(currentBlock.timestamp - BigInt(payload.delay) - 1n), // altering queued time so can be executed in current block
              payload.createdAt,
              PayloadState.Queued,
              payload.maximumAccessLevelRequired,
              payload.creator,
            ]
          ),
        },
      },
    },
  };
  return simulationPayload;
};
