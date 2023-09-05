import {
  Address,
  encodeAbiParameters,
  encodePacked,
  Hex,
  parseAbiParameters,
  parseEther,
  PublicClient,
  WalletClient,
} from 'viem';
import VotingPortal from './artifacts/VotingPortal.sol/VotingPortal.json';
import {
  AaveV3Ethereum,
  AaveV3EthereumAssets,
  GovernanceV3Ethereum,
} from '@bgd-labs/aave-address-book';
import {V3_EXECUTOR_ABI} from './abis/V3ExecutorAbi';
import {create3Deploy, create3GetAddress} from './create3';
import VotingMachine from './artifacts/VotingMachine.sol/VotingMachine.json';

const VOTING_PORTAL_SALT = 'VotingPortal salt test';
const VOTING_STRATEGY = '0x5642A5A5Ec284B4145563aBF319620204aCCA7f4';

export const changeExecutorsOwner = async (
  newOwner: Address,
  executor: Address,
  publicClient: PublicClient,
  walletClient: WalletClient
) => {
  const {request} = await publicClient.simulateContract({
    address: executor,
    abi: V3_EXECUTOR_ABI,
    functionName: 'transferOwnership',
    args: [newOwner],
    account: GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
  });
  await walletClient.writeContract(request);
};

export const deployVotingMachine = async (
  deployer: Address,
  publicClient: PublicClient,
  walletClient: WalletClient
) => {
  const votingPortalAddress = create3GetAddress(publicClient, VOTING_PORTAL_SALT, deployer);
  const bytecode = VotingMachine.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: VotingMachine.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      250000n,
      1n,
      VOTING_STRATEGY,
      votingPortalAddress,
      GovernanceV3Ethereum.GOVERNANCE,
    ],
  });

  const transaction = await publicClient.waitForTransactionReceipt({hash});

  // set voting machine as sender

  return transaction.contractAddress as Hex;
};

export const deployVotingPortal = async (
  newVotingMachine: Address,
  deployer: Address,
  publicClient: PublicClient,
  walletClient: WalletClient
) => {
  const encodedParams = encodeAbiParameters(
    parseAbiParameters('address, address, address, uint256, uint256, address'),
    [
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      GovernanceV3Ethereum.GOVERNANCE,
      newVotingMachine,
      1n,
      300000n,
      deployer,
    ]
  );
  // abi.encodePacked(code, encodedParams)
  const creationCode = encodePacked(
    ['bytes', 'bytes'],
    [VotingPortal.bytecode.object as Hex, encodedParams]
  );
  const votingPortalAddress = await create3Deploy(
    publicClient,
    walletClient,
    VOTING_PORTAL_SALT,
    creationCode,
    deployer
  );

  // set voting portal as sender
  // set voting portal in gov

  return votingPortalAddress;
};

export const;
