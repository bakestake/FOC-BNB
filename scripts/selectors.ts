/* eslint-disable */
/* prettier-ignore */
const chainFacetSelectorsKeys = [
    "0xfd2b5202",
    "0xeacaeb15",
    "0xad004e20",
    "0x372500ab",
    "0x150b7a02",
    "0x2f914df2",
    "0xe8e058ce",
    "0xba932e98",
    "0xa0b966ce"
];

/* prettier-ignore */
const crossChainFacetSelectorKeys = [
    "0x58193822",
    "0xad3cb1cc",
    "0x95fa8b8e",
    "0x180dcecc",
    "0xff7bd03d",
    "0x0670c77e",
    "0xfa55adf1",
    "0xab748516",
    "0x5e280f11",
    "0xc8ee3d0a",
    "0x82413eac",
    "0x13137d65",
    "0x7d25a05e",
    "0x17442b70",
    "0x8da5cb5b",
    "0xbb0b6a53",
    "0x52d1902d",
    "0x715018a6",
    "0xca5eb5e1",
    "0x3400288b",
    "0xf2fde38b",
    "0x4f1ef286",
    "0xe1c7392a",
    "0x8f9c24e7"
]


/* prettier-ignore */
const diamondLoupeSelector = [
	"0xcdffacc6",
	"0x52ef6b2c",
	"0xadfca15e",
	"0x7a0ed627",
	"0x01ffc9a7"
]

/* prettier-ignore */
const getterSetterSelector =[
    "0xa094c632",
    "0xbe782e91",
    "0x5ec6bd9f",
    "0x0903b335",
    "0xd8b84491",
    "0x658b6729",
    "0xed89eb30",
    "0xc9990c2a",
    "0x842e2981",
    "0x4269e94c",
    "0x2d6fe6e1",
    "0x25970f6d",
    "0xadb73624",
    "0xe2197110",
    "0xf0f44260",
    "0x1765634b",
    "0x4fb2e45d",
    "0xa0ef91df"
]



const stateUpdateSelector = [
  "0x1cbc2a82",
  // "0x9fd314f7",
  "0x9bafae0e"
];

const burnFacetSelector = [
    "0xc049cf5f",
    "0x7c958d28",
    "0x338b93e6"
]


const raidHandlerSelector = ["0x11778b65", "0xb43d0375"];

const raidHandlerAltSelector = ["0x52a5f1f8", "0xb59ee46d"];

export const getSelector = (contractName: string) => {
  switch (contractName) {
    case "ChainFacet":
      return chainFacetSelectorsKeys;
    case "CrossChainFacet":
      return crossChainFacetSelectorKeys;
    case "DiamondLoupeFacet":
      return diamondLoupeSelector;
    case "GetterSetterFacet":
      return getterSetterSelector;
    case "StateUpdate":
      return stateUpdateSelector;
    case "RaidHandler":
      return raidHandlerSelector;
    case "BurnFacet":
      return burnFacetSelector;
    default:
      break;
  }
};
