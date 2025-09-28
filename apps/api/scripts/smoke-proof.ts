import { getProofOfReserves } from '../src/services/proofBalances';

(async () => {
  const data = await getProofOfReserves();
  console.log(JSON.stringify(data, null, 2));
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
