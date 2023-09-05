import {Address, PublicClient, WalletClient} from 'viem';
import ATokenWithDelegation from './artifacts/ATokenWithDelegation.sol/ATokenWithDelegation.json';
import {
  AaveV3Ethereum,
  AaveV3EthereumAssets,
  GovernanceV3Ethereum,
} from '@bgd-labs/aave-address-book';
import {V3_EXECUTOR_ABI} from './abis/V3ExecutorAbi';

export const changeExecutorsOwner = async (
  newOwner: Address,
  executor: Address,
  publicClient: PublicClient,
  walletClient: WalletClient
) => {
  const {request} = await publicClient.simulateContract({
    address: GovernanceV3Ethereum.EXECUTOR_LVL_1,
    abi: V3_EXECUTOR_ABI,
    functionName: 'transferOwnership',
    args: [newOwner],
    account: GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
  });
  await walletClient.writeContract(request);
};
