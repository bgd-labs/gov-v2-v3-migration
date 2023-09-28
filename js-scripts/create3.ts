import {
  Address,
  getContract,
  Hex,
  keccak256,
  PublicClient,
  stringToBytes,
  WalletClient,
} from 'viem';
import Create3Factory from './artifacts/Create3Factory.sol/Create3Factory.json';

const CREATE_3_FACTORY = '0xcc3C54B95f3f1867A43009B80ed4DD930E3cE2F7'; // TODO: add to address book

export const encodeSalt = (salt: string) => {
  return keccak256(stringToBytes(salt));
};
export const create3GetAddress = async (
  publicClient: PublicClient,
  salt: string,
  deployer: Address
) => {
  const create3Factory = getContract({
    address: CREATE_3_FACTORY,
    abi: Create3Factory.abi,
    publicClient,
  });

  return create3Factory.read.predictAddress([deployer, encodeSalt(salt)]);
};

export const create3Deploy = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  salt: string,
  creationCode: Hex,
  deployer: Address
) => {
  const encodedSalt = encodeSalt(salt);
  const {request, result} = await publicClient.simulateContract({
    address: CREATE_3_FACTORY,
    abi: Create3Factory.abi,
    functionName: 'create',
    args: [encodedSalt, creationCode],
    account: deployer,
  });
  await walletClient.writeContract(request);

  return result;
};
