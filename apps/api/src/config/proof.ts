export type ChainKey = 'COSMOS'|'TIA'|'TERRA'|'JUNO'|'BAND'|'ARBITRUM'|'BASE';
export type AssetSym = 'ATOM'|'TIA'|'LUNA'|'JUNO'|'BAND'|'ETH'|'PI';

export interface PoRAddress {
  chain: ChainKey;
  asset: AssetSym; // native token symbol on that chain
  address: string;
  explorerUrl: (addr: string) => string;
}

export const PROOF_ADDRESSES: PoRAddress[] = [
  { chain:'COSMOS',   asset:'ATOM', address:'cosmos1xhdm4xccpqsvcxel5amf4r32e86q9k48x7aqjx', explorerUrl: a => `https://www.mintscan.io/cosmos/account/${a}` },
  { chain:'ARBITRUM', asset:'ETH',  address:'0x1660Ef3e78FA3f04289B773b6ccF3666DBB6c7B5', explorerUrl: a => `https://arbiscan.io/address/${a}` },
  { chain:'BASE',     asset:'ETH',  address:'0x1660Ef3e78FA3f04289B773b6ccF3666DBB6c7B5', explorerUrl: a => `https://basescan.org/address/${a}` },
  { chain:'TIA',      asset:'TIA',  address:'celestia1xhdm4xccpqsvcxel5amf4r32e86q9k48h5vsgt', explorerUrl: a => `https://www.mintscan.io/celestia/account/${a}` },
  { chain:'TERRA',    asset:'LUNA', address:'terra15hf2ad99amu5x3edd99jnv049cwqrga6yf5hc2', explorerUrl: a => `https://finder.terra.money/mainnet/address/${a}` },
  { chain:'JUNO',     asset:'JUNO', address:'juno1xhdm4xccpqsvcxel5amf4r32e86q9k48sv7m46', explorerUrl: a => `https://www.mintscan.io/juno/account/${a}` },
  { chain:'BAND',     asset:'BAND', address:'band13df4yakp3d429e503gmqw7tdvfg3d9dd6uzjnr', explorerUrl: a => `https://www.mintscan.io/band/account/${a}` },
];

export function explorerFor(chain: ChainKey, address: string): string {
  const entry = PROOF_ADDRESSES.find(p => p.chain === chain && p.address === address);
  if (entry) return entry.explorerUrl(address);
  return address;
}
