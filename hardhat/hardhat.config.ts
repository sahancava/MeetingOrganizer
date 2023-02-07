import { HardhatUserConfig } from 'hardhat/config';
import "@nomicfoundation/hardhat-toolbox";
import "xdeployer";
/** @type import('hardhat/config').HardhatUserConfig */

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337
    }
  },
  // xdeploy: {
  //   contract: "YOUR_CONTRACT_NAME_TO_BE_DEPLOYED",
  //   constructorArgsPath: "PATH_TO_CONSTRUCTOR_ARGS",
  //   salt: "YOUR_SALT_MESSAGE",
  //   signer: "SIGNER_PRIVATE_KEY",
  //   networks: ["LIST_OF_NETWORKS"],
  //   rpcUrls: ["LIST_OF_RPCURLS"],
  //   gasLimit: "GAS_LIMIT",
  // }
}

export default config;