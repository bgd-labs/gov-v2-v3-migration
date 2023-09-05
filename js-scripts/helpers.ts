import {
  Address,
  encodeAbiParameters,
  fromHex,
  getContract,
  Hex,
  keccak256,
  pad,
  parseAbiParameters,
  PublicClient,
  toHex,
  trim,
  WalletClient,
} from 'viem';
import {AaveGovernanceV2, IAaveGovernanceV2_ABI} from '@bgd-labs/aave-address-book';

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
