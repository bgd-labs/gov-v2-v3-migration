// - deploy aave token implementation
import {Address, getContract, Hex, PublicClient, WalletClient} from 'viem';
import AaveTokenV3 from './artifacts/AaveTokenV3.sol/AaveTokenV3.json';
import StakedAaveV3 from './artifacts/StakedAaveV3.sol/StakedAaveV3.json';
import ATokenWithDelegation from './artifacts/ATokenWithDelegation.sol/ATokenWithDelegation.json';
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

  return transaction.contractAddress;
};

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

  return transaction.contractAddress;
};

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

// - deploy stkAave token implementation
// - deploy aAave token implementation

// deploy all payloads

// - deploy aave update payload
// - deploy stkAave update payload
// - deploy aAave update payload

// - deploy short executor payload
// - deploy long executor payload
