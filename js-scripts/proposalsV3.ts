import {
  Address,
  encodeAbiParameters,
  encodePacked,
  getContract,
  Hex,
  parseAbiParameters,
  PublicClient,
  WalletClient,
} from 'viem';
import VotingPortal from './artifacts/VotingPortal.sol/VotingPortal.json';
import {
  GovernanceV3Ethereum,
  ICrossChainController_ABI,
  IGovernanceCore_ABI,
  IOwnable_ABI,
  IPayloadsControllerCore_ABI,
} from '@bgd-labs/aave-address-book';
import {create3Deploy, create3GetAddress} from './create3';
import VotingMachine from './artifacts/VotingMachine.sol/VotingMachine.json';
import {getPayloadsController, tenderly} from '@bgd-labs/aave-cli';
import {deployContract} from './helpers';

const VOTING_PORTAL_SALT = 'VotingPortal salt test';
const VOTING_STRATEGY = '0x5642A5A5Ec284B4145563aBF319620204aCCA7f4';

export type Actions = {
  target: Address;
  withDelegateCall: boolean;
  accessLevel: number;
  value: bigint;
  signature: string;
  callData: Hex;
};

export type Payload = {
  chain: bigint;
  accessLevel: number;
  payloadsController: Address;
  payloadId: number;
};

export const changeExecutorsOwner = async (
  newOwner: Address,
  executor: Address,
  publicClient: PublicClient,
  walletClient: WalletClient
) => {
  const {request} = await publicClient.simulateContract({
    address: executor,
    abi: IOwnable_ABI,
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
  const votingPortalAddress = await create3GetAddress(publicClient, VOTING_PORTAL_SALT, deployer);
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
  const votingMachineAddress = transaction.contractAddress as Hex;

  // set voting machine as sender
  const {request} = await publicClient.simulateContract({
    address: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
    abi: ICrossChainController_ABI,
    functionName: 'approveSenders',
    args: [[votingMachineAddress]],
    account: deployer,
  });
  await walletClient.writeContract(request);

  return votingMachineAddress;
};

export const deployVotingPortal = async (
  newVotingMachine: Address,
  deployer: Address,
  publicClient: PublicClient,
  walletClient: WalletClient
): Promise<Address> => {
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
  const {request} = await publicClient.simulateContract({
    address: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
    abi: ICrossChainController_ABI,
    functionName: 'approveSenders',
    args: [[votingPortalAddress as Hex]],
    account: deployer,
  });
  await walletClient.writeContract(request);

  // set voting portal in gov
  const {request: requestVP_GOV} = await publicClient.simulateContract({
    address: GovernanceV3Ethereum.GOVERNANCE,
    abi: IGovernanceCore_ABI,
    functionName: 'addVotingPortals',
    args: [[votingPortalAddress as Hex]],
    account: deployer,
  });
  await walletClient.writeContract(requestVP_GOV);

  return votingPortalAddress as Address;
};

export const deployAndRegisterTestPayloads = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address,
  controller: any,
  payloadArtifacts: any[]
) => {
  const actions: Actions[] = [];
  for (let i = 0; i < payloadArtifacts.length; i++) {
    const payload = await deployContract(walletClient, publicClient, deployer, payloadArtifacts[i]);
    actions.push({
      target: payload,
      withDelegateCall: true,
      value: 0n,
      signature: 'execute()',
      accessLevel: 1,
      callData: '' as Hex,
    });
  }
  // register payloads
  const {request: payloadRegistered, result: payloadId} = await publicClient.simulateContract({
    address: controller,
    abi: IPayloadsControllerCore_ABI,
    functionName: 'createPayload',
    args: [actions],
    account: deployer,
  });
  await walletClient.writeContract(payloadRegistered);
  return payloadId;
};

export const generateProposalAndExecutePayload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  fork: any,
  deployer: Address,
  payloadId: number,
  chain: any
) => {
  const govContract = getContract({
    address: GovernanceV3Ethereum.GOVERNANCE,
    abi: IGovernanceCore_ABI,
    publicClient,
  });
  const fee = await govContract.read.getCancellationFee();

  await tenderly.fundAccount(fork, deployer);

  const payloads: Payload[] = [];
  payloads.push({
    payloadsController: GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
    chain: chain.id,
    payloadId,
    accessLevel: 1,
  });

  const {request, result: proposalId} = await publicClient.simulateContract({
    address: GovernanceV3Ethereum.GOVERNANCE,
    abi: IGovernanceCore_ABI,
    functionName: 'createProposal',
    args: [
      payloads,
      GovernanceV3Ethereum.VOTING_PORTAL_ETH_ETH,
      '0x22f22ad910127d3ca76dc642f94db34397f94ca969485a216b9d82387808cdfa' as Hex,
    ],
    value: fee,
    account: deployer,
  });
  await walletClient.writeContract(request);

  const payloadController = await getPayloadsController(
    GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
    // @ts-ignore
    publicClient
  );
  const payload = await payloadController.getSimulationPayloadForExecution(payloadId);
  await tenderly.unwrapAndExecuteSimulationPayloadOnFork(fork, payload);

  return proposalId;
};
