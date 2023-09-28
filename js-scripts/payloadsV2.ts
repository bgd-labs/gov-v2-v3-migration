// - deploy aave token implementation
import {tenderly} from '@bgd-labs/aave-cli';
import {getTenderlyActionSetCreationPayload} from 'aave-cli';
import {Address, PublicClient, WalletClient, getContract} from 'viem';
import {EOA} from './helpers';

const executorABI = [
  {
    inputs: [],
    name: 'getActionsSetCount',
    outputs: [{internalType: 'uint256', name: '', type: 'uint256'}],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getGracePeriod',
    outputs: [{internalType: 'uint256', name: '', type: 'uint256'}],
    stateMutability: 'view',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [
      {indexed: true, internalType: 'uint256', name: 'id', type: 'uint256'},
      {
        indexed: true,
        internalType: 'address',
        name: 'initiatorExecution',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'bytes[]',
        name: 'returnedData',
        type: 'bytes[]',
      },
    ],
    name: 'ActionsSetExecuted',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      {indexed: true, internalType: 'uint256', name: 'id', type: 'uint256'},
      {
        indexed: false,
        internalType: 'address[]',
        name: 'targets',
        type: 'address[]',
      },
      {
        indexed: false,
        internalType: 'uint256[]',
        name: 'values',
        type: 'uint256[]',
      },
      {
        indexed: false,
        internalType: 'string[]',
        name: 'signatures',
        type: 'string[]',
      },
      {
        indexed: false,
        internalType: 'bytes[]',
        name: 'calldatas',
        type: 'bytes[]',
      },
      {
        indexed: false,
        internalType: 'bool[]',
        name: 'withDelegatecalls',
        type: 'bool[]',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'executionTime',
        type: 'uint256',
      },
    ],
    name: 'ActionsSetQueued',
    type: 'event',
  },
  {
    inputs: [{internalType: 'uint256', name: 'actionsSetId', type: 'uint256'}],
    name: 'execute',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
  {
    inputs: [
      {internalType: 'address[]', name: 'targets', type: 'address[]'},
      {internalType: 'uint256[]', name: 'values', type: 'uint256[]'},
      {internalType: 'string[]', name: 'signatures', type: 'string[]'},
      {internalType: 'bytes[]', name: 'calldatas', type: 'bytes[]'},
      {internalType: 'bool[]', name: 'withDelegatecalls', type: 'bool[]'},
    ],
    name: 'queue',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const;

export const executeL2Payload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  executor: Address,
  payload: Address,
  fork: any
) => {
  //

  // await walletClient.writeContract({
  //   address: payload,
  //   abi,
  //   functionName: 'execute',
  //   args: [],
  //   account: executor,
  //   chain: undefined,
  // });
  const contract = getContract({abi: executorABI, address: executor, publicClient});

  const tenderlyPayload = await getTenderlyActionSetCreationPayload(
    contract as any,
    publicClient as any,
    {
      targets: [payload],
      values: [0n],
      calldatas: ['0x0'],
      signatures: ['execute()'],
      withDelegatecalls: [true],
    }
  );
  return tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, tenderlyPayload);
  // return result;
};

const mockExecutorBytes =
  '0x608060405234801561001057600080fd5b506004361061002b5760003560e01c80634b64e49214610030575b600080fd5b61004361003e366004610120565b610045565b005b60408051600481526024810182526020810180516001600160e01b0316631851865560e21b17905290516000916001600160a01b038416916100879190610150565b600060405180830381855af49150503d80600081146100c2576040519150601f19603f3d011682016040523d82523d6000602084013e6100c7565b606091505b505090508061011c5760405162461bcd60e51b815260206004820152601960248201527f50524f504f53414c5f455845435554494f4e5f4641494c454400000000000000604482015260640160405180910390fd5b5050565b60006020828403121561013257600080fd5b81356001600160a01b038116811461014957600080fd5b9392505050565b6000825160005b818110156101715760208186018101518583015201610157565b81811115610180576000828501525b50919091019291505056fea2646970667358221220b5e76617250f070df5d6bc01dcf608005afb0c19aa2776724a1b25684f561c4664736f6c634300080a0033';

const MOCK_EXECUTOR = [
  {
    inputs: [
      {
        internalType: 'address',
        name: 'payload',
        type: 'address',
      },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
    name: 'execute',
  },
] as const;
export const executeL2PayloadViaGuardian = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  executor: Address,
  payload: Address,
  fork: any
) => {
  await tenderly.replaceCode(fork, executor, mockExecutorBytes);
  const {request, result} = await publicClient.simulateContract({
    address: executor,
    abi: MOCK_EXECUTOR,
    functionName: 'execute',
    args: [payload],
    account: EOA,
  });
  const hash = await walletClient.writeContract(request);
  await publicClient.waitForTransactionReceipt({hash});
};
