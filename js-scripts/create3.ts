import {encodeAbiParameters, getContract, keccak256, PublicClient} from 'viem';
import Create3Factory from './artifacts/Create3Factory.sol/Create3Factory.json';

const CREATE_3_FACTORY = '0xcc3C54B95f3f1867A43009B80ed4DD930E3cE2F7'; // TODO: add to address book
export const create3GetAddress = async (publicClient: PublicClient, salt: string) => {
  const create3Factory = getContract({
    address: CREATE_3_FACTORY,
    abi: Create3Factory.abi,
    publicClient,
  });

  const encodedSalt = keccak256(encodeAbiParameters(['string'], salt));
};

export const create3Deploy = async () => {};
