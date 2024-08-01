import {ADDRESES} from "../../constants/constants";

export const getConstants = async (networkName: string) => {
  switch (networkName) {
    case "polygon":
      return ADDRESES.polygon;
    case "amoy":
      return ADDRESES.amoy;
    case "bsc":
      return ADDRESES.bsc;
    case "bscTestnet":
      return ADDRESES.bscTestnet;
    case "avalanche":
      return ADDRESES.avalanche;
    case "fuji":
      return ADDRESES.fuji;
    case "arbitrum":
      return ADDRESES.arbitrum;
    case "arbSepolia":
      return ADDRESES.arbSepolia;
    case "beraTestnet":
      return ADDRESES.bera_batrio;
    case "coreTestnet":
      return ADDRESES.coreTestnet;
    case "baseSepolia":
      return ADDRESES.baseSpolia
  }
};
