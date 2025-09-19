import { getPrices, type SupportedSymbol } from '@hyapi/prices';

async function main() {
  const wanted: SupportedSymbol[] = ['PI','LUNA','BAND','JUNO','ATOM','TIA','DAI'];
  const res = await getPrices(wanted).catch(e => ({ prices: Object.fromEntries(wanted.map(s=>[s,0])) as any, asOf: new Date().toISOString(), degraded: true, source: 'fallback' as const }));
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(res, null, 2));
}

main();
