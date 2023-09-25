// - deploy aave token implementation
import {Address, PublicClient, WalletClient} from 'viem';

export const executeL2Payload = async (
  walletClient: WalletClient,
  publicClient: PublicClient,
  executor: Address,
  payload: Address,
  abi: any
) => {
  // const {request, result} = await publicClient.simulateContract({
  //   address: payload,
  //   abi,
  //   functionName: 'execute',
  //   args: [],
  //   account: executor,
  // });
  // const hash = await walletClient.writeContract(request);
  // await publicClient.waitForTransactionReceipt({hash});

  await walletClient.writeContract({
    address: payload,
    abi,
    functionName: 'execute',
    args: [],
    account: executor,
    chain: undefined,
  });

  // return result;
};
