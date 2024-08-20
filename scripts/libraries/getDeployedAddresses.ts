import {DeployedAddresses} from "../../constants/deployedAddresses";

export const getDeployedAddressesForChain = (networkName: string) => {
  switch (networkName) {
    case "polygon":
      return DeployedAddresses.polygon;
    case "amoy":
      return DeployedAddresses.amoy;
    case "bsc":
      return DeployedAddresses.bsc;
    case "bscTestnet":
      return DeployedAddresses.bscTestnet;
    case "avalanche":
      return DeployedAddresses.avalanche;
    case "fuji":
      return DeployedAddresses.fuji;
    case "arbitrum":
      return DeployedAddresses.arbitrum;
    case "arbSepolia":
      return DeployedAddresses.arbSepolia;
    case "beraTestnet":
      return DeployedAddresses.bera_batrio;
    // case "coreTestnet":
    //   return DeployedAddresses.coreTestnet;
    case "baseSepolia":
      return DeployedAddresses.baseSepolia;
  }
};
