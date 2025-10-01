export type ChainKey = 'COSMOS'|'TIA'|'TERRA'|'JUNO'|'BAND'|'ARBITRUM'|'BASE';
export type AssetSym = 'ATOM'|'TIA'|'LUNA'|'JUNO'|'BAND'|'ETH'|'PI';

export const ADDRESSES: Record<string, { chain: ChainKey; asset: AssetSym; address: string; explorer?: (a:string)=>string }> = {
  COSMOS_ATOM:    { chain:'COSMOS',   asset:'ATOM', address:'cosmos1xhdm4xccpqsvcxel5amf4r32e86q9k48x7aqjx' },
  ARBITRUM_ETH:   { chain:'ARBITRUM', asset:'ETH',  address:'0x1660Ef3e78FA3f04289B773b6ccF3666DBB6c7B5' },
  BASE_ETH:       { chain:'BASE',     asset:'ETH',  address:'0x1660Ef3e78FA3f04289B773b6ccF3666DBB6c7B5' },
  TIA_TIA:        { chain:'TIA',      asset:'TIA',  address:'celestia1xhdm4xccpqsvcxel5amf4r32e86q9k48h5vsgt' },
  TERRA_LUNA:     { chain:'TERRA',    asset:'LUNA', address:'terra15hf2ad99amu5x3edd99jnv049cwqrga6yf5hc2' },
  JUNO_JUNO:      { chain:'JUNO',     asset:'JUNO', address:'juno1xhdm4xccpqsvcxel5amf4r32e86q9k48sv7m46' },
  BAND_BAND:      { chain:'BAND',     asset:'BAND', address:'band13df4yakp3d429e503gmqw7tdvfg3d9dd6uzjnr' },
};

export function addressForChain(chain: ChainKey): string | null {
  const entry = Object.values(ADDRESSES).find(a => a.chain === chain);
  return entry?.address ?? null;
}
export function addressForAsset(sym: AssetSym): string | null {
  const entry = Object.values(ADDRESSES).find(a => a.asset === sym);
  return entry?.address ?? null;
}
