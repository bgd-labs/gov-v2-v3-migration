// - deploy aave token implementation
import {Address, getContract, Hex, PublicClient, WalletClient} from 'viem';
import AaveTokenV3 from './artifacts/AaveTokenV3.sol/AaveTokenV3.json';
import StakedAaveV3 from './artifacts/StakedAaveV3.sol/StakedAaveV3.json';
import ATokenWithDelegation from './artifacts/ATokenWithDelegation.sol/ATokenWithDelegation.json';
import UpdateAaveTokenPayload from './artifacts/UpdateAaveTokenPayload.sol/UpdateAaveTokenPayload.json';
import UpdateAAavePayload from './artifacts/UpdateAAavePayload.sol/UpdateAAavePayload.json';
import UpdateStkAavePayload from './artifacts/ProposalPayload.sol/UpdateStkAavePayload.json';
import EthShortMovePermissionsPayload from './artifacts/EthShortMovePermissionsPayload.sol/EthShortMovePermissionsPayload.json';
import EthLongMovePermissionsPayload from './artifacts/EthLongMovePermissionsPayload.sol/EthLongMovePermissionsPayload.json';
import {
  GovernanceV3Ethereum,
  AaveV3EthereumAssets,
  AaveMisc,
  AaveV3Ethereum,
} from '@bgd-labs/aave-address-book';

export const deployAaveImpl = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address
) => {
  const bytecode = AaveTokenV3.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: AaveTokenV3.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});
  // console.log('tx: ', transaction);
  const aaveTokenImplAddress = transaction.contractAddress as Hex;

  const {request} = await publicClient.simulateContract({
    address: aaveTokenImplAddress,
    abi: AaveTokenV3.abi,
    functionName: 'initialize',
    account: deployer,
    args: [],
  });
  await walletClient.writeContract(request);

  return aaveTokenImplAddress;
};

// - deploy stkAave token implementation
export const deployStkAaveImpl = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address
) => {
  const unstakeWindow = '172800';
  const distributionDuration = '3155692600';
  const emissionManager = GovernanceV3Ethereum.EXECUTOR_LVL_1;

  const bytecode = StakedAaveV3.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: StakedAaveV3.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [
      AaveV3EthereumAssets.AAVE.UNDERLYING,
      AaveV3EthereumAssets.AAVE.UNDERLYING,
      unstakeWindow,
      AaveMisc.ECOSYSTEM_RESERVE,
      emissionManager,
      distributionDuration,
    ],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});
  // console.log('tx: ', transaction);

  return transaction.contractAddress as Hex;
};

// - deploy aAave token implementation
export const deployAAaveImpl = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address
): Promise<Hex> => {
  const bytecode = ATokenWithDelegation.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: ATokenWithDelegation.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [AaveV3Ethereum.POOL],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});
  // console.log('tx: ', transaction);

  const aAaveImplAddress = transaction.contractAddress as Hex;

  // call initialize
  const {request} = await publicClient.simulateContract({
    address: aAaveImplAddress,
    abi: ATokenWithDelegation.abi,
    functionName: 'initialize',
    args: [
      AaveV3Ethereum.POOL,
      AaveV3EthereumAssets.AAVE.UNDERLYING,
      AaveV3Ethereum.COLLECTOR,
      AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
      18,
      'Aave Ethereum AAVE',
      'aEthAAVE',
      '0x10',
    ],
    account: deployer,
  });
  await walletClient.writeContract(request);

  return aAaveImplAddress;
};

// deploy all payloads

// - deploy aave update payload
export const deployAaveTokenPayload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address,
  aaveTokenImplAddress: Address
) => {
  const bytecode = UpdateAaveTokenPayload.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: UpdateAaveTokenPayload.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [aaveTokenImplAddress],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  return transaction.contractAddress as Hex;
};

// - deploy stkAave update payload
export const deployStkAaveTokenPayload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address,
  stkAaveTokenImplAddress: Address
) => {
  const bytecode = UpdateStkAavePayload.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: UpdateStkAavePayload.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [stkAaveTokenImplAddress],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  return transaction.contractAddress as Hex;
};

// - deploy aAave update payload
export const deployAAaveTokenPayload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address,
  aAaveTokenImplAddress: Address
) => {
  const bytecode = UpdateAAavePayload.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: UpdateAAavePayload.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [aAaveTokenImplAddress],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  return transaction.contractAddress as Hex;
};

// - deploy short executor payload
export const deployShortPermissionsPayload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address
) => {
  const bytecode = EthShortMovePermissionsPayload.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: EthShortMovePermissionsPayload.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  return transaction.contractAddress as Hex;
};

// - deploy long executor payload
export const deployLongPermissionsPayload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address
) => {
  const bytecode = EthLongMovePermissionsPayload.bytecode.object as Hex;
  const hash = await walletClient.deployContract({
    abi: EthLongMovePermissionsPayload.abi,
    account: deployer,
    bytecode: bytecode,
    chain: undefined,
    args: [],
  });
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  return transaction.contractAddress as Hex;
};
