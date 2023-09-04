// create v2 short proposal
// create v2 long proposal

// execute proposals

import {
  AaveGovernanceV2,
  AaveV3Ethereum,
  AaveV3EthereumAssets,
  IAaveGovernanceV2_ABI,
} from '@bgd-labs/aave-address-book';
import ATokenWithDelegation from './artifacts/ATokenWithDelegation.sol/ATokenWithDelegation.json';
import {Address, Hex, PublicClient, WalletClient} from 'viem';

// create v2 short proposal
export const createShortV2Proposal = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  deployer: Address,
  targetAddresses: Address[]
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

  const {request} = await publicClient.simulateContract({
    address: AaveGovernanceV2.GOV,
    abi: IAaveGovernanceV2_ABI,
    functionName: 'create',
    args: [
      AaveGovernanceV2.SHORT_EXECUTOR,
      targets,
      values,
      signatures,
      calldatas,
      withDelegateCalls,
      '0x22f22ad910127d3ca76dc642f94db34397f94ca969485a216b9d82387808cdfa' as Hex, //ipfsHash,
    ],
    account: deployer,
  });
  const hash = await walletClient.writeContract(request);
  const transaction = await publicClient.waitForTransactionReceipt({hash});

  console.log('txproposal: ', transaction);
  return 9;
};
