import axios from 'axios';
import * as StellarSdk from 'stellar-sdk';

type CreateA2UInput = {
  uid: string;
  amount: number; // Pi amount as decimal number
  memo?: string;
  metadata?: any;
};

export type CreateA2UResult = {
  identifier: string;
  txid: string;
};

const API_BASE = process.env.PI_API_BASE?.replace(/\/?$/, '') || 'https://api.minepi.com/v2';
const API_KEY = process.env.PI_API_KEY || '';
const APP_PUBLIC = process.env.PI_APP_PUBLIC || '';
const APP_SECRET = process.env.PI_APP_SECRET || '';

function requireEnv() {
  if (!API_KEY) throw new Error('PI_API_KEY missing');
  if (!APP_PUBLIC) throw new Error('PI_APP_PUBLIC missing');
  if (!APP_SECRET) throw new Error('PI_APP_SECRET missing');
}

function horizonConfig() {
  const net = (process.env.PI_NETWORK || 'TESTNET').toUpperCase();
  if (net === 'MAINNET' || net === 'MAIN') {
    return {
      horizonUrl: process.env.PI_HORIZON || 'https://api.mainnet.minepi.com',
      networkPassphrase: process.env.PI_NETWORK_PASSPHRASE || 'Pi Network',
    };
  }
  // default Testnet
  return {
    horizonUrl: process.env.PI_HORIZON || 'https://api.testnet.minepi.com',
    networkPassphrase: process.env.PI_NETWORK_PASSPHRASE || 'Pi Testnet',
  };
}

function formatAmount(n: number): string {
  // Stellar supports up to 7 decimal places. Limit to 6 for safety.
  if (!Number.isFinite(n) || n <= 0) throw new Error('invalid amount');
  return n.toFixed(6);
}

export async function createA2U({ uid, amount, memo, metadata }: CreateA2UInput): Promise<CreateA2UResult> {
  requireEnv();
  const { horizonUrl, networkPassphrase } = horizonConfig();

  const http = axios.create({ baseURL: API_BASE, timeout: 20000 });
  const headers = { Authorization: `Key ${API_KEY}`, 'Content-Type': 'application/json' };

  // 1) Create payment on Platform
  const body = { amount, memo: memo ?? 'A2U payment', metadata: metadata ?? {}, uid };
  const createRes = await http.post('/payments', body, { headers });
  const identifier: string = createRes.data?.identifier ?? createRes.data?.paymentId;
  const recipient: string = createRes.data?.recipient || createRes.data?.to_address || createRes.data?.toAddress;
  if (!identifier) throw new Error('Create A2U: missing identifier');
  if (!recipient) throw new Error('Create A2U: missing recipient address');

  // 2) Load app account & fees
  const server = new StellarSdk.Server(horizonUrl);
  const account = await server.loadAccount(APP_PUBLIC);
  const baseFee = await server.fetchBaseFee();
  const timebounds = await server.fetchTimebounds(180);

  // 3) Build transaction with memo=identifier
  const op = StellarSdk.Operation.payment({
    destination: recipient,
    asset: StellarSdk.Asset.native(),
    amount: formatAmount(amount),
  });
  let tx = new StellarSdk.TransactionBuilder(account, {
    fee: baseFee.toString(),
    networkPassphrase,
    timebounds,
  })
    .addOperation(op)
    .addMemo(StellarSdk.Memo.text(identifier))
    .setTimeout(180)
    .build();

  // 4) Sign & submit
  const keypair = StellarSdk.Keypair.fromSecret(APP_SECRET);
  tx.sign(keypair);
  const submitRes = await server.submitTransaction(tx);
  const txid: string = (submitRes as any)?.id || (submitRes as any)?.hash || tx.hash().toString('hex');
  if (!txid) throw new Error('Submit A2U: missing txid');

  // 5) Complete on Platform
  await http.post(`/payments/${encodeURIComponent(identifier)}/complete`, { txid }, { headers });

  return { identifier, txid };
}
