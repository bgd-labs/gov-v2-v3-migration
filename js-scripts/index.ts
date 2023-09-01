import 'dotenv/config';
import {tenderly} from '@bgd-labs/aave-cli';
import path from 'path';
import {createPublicClient, createWalletClient, http} from 'viem';
import {mainnet} from 'viem/chains';
import {
  deployAAaveImpl,
  deployAAaveTokenPayload,
  deployAaveImpl,
  deployAaveTokenPayload,
  deployStkAaveImpl,
  deployStkAaveTokenPayload,
} from './payloadsV2';

export const DEPLOYER = '0x6D603081563784dB3f83ef1F65Cc389D94365Ac9';
// create mainnet fork
const getFork = async () => {
  const fork = await tenderly.fork({chainId: 1, alias: 'govV3Fork'});

  return fork;
};

const deployPayloadsV2 = async () => {
  const fork = await getFork();

  const walletClient = createWalletClient({
    account: '0x0', // TODO: create some proper address
    chain: {...mainnet, id: 3030, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  const publicClient = createPublicClient({
    chain: {...mainnet, id: 3030, name: 'tenderly'},
    transport: http(fork.forkUrl),
  });

  // deploy token implementations
  const aaveTokenV3Impl = await deployAaveImpl(walletClient, publicClient, DEPLOYER);
  const stkAaveTokenV3 = await deployStkAaveImpl(walletClient, publicClient, DEPLOYER);
  const aAaveTokenV3 = await deployAAaveImpl(walletClient, publicClient, DEPLOYER);

  // deploy payloads

  const aaveTokenPayload = await deployAaveTokenPayload(
    walletClient,
    publicClient,
    DEPLOYER,
    aaveTokenV3Impl
  );
  const stkAaveTokenPayload = await deployStkAaveTokenPayload(
    walletClient,
    publicClient,
    DEPLOYER,
    stkAaveTokenV3
  );
  const aAaveTokenPayload = await deployAAaveTokenPayload(
    walletClient,
    publicClient,
    DEPLOYER,
    aAaveTokenV3
  );
};

deployPayloadsV2().then().catch(console.log);
