# hyaPi Monorepo

## A2U payouts: environment and dev behavior

Server-side A2U (App-to-User) payouts require signing and submitting a Stellar transaction from your app wallet, then completing the payment on the Pi Platform.

Required environment variables (apps/api/.env):

- PI_API_BASE: Pi Platform API base (default `https://api.minepi.com/v2`)
- PI_API_KEY: Your Pi app API key
- PI_APP_PUBLIC: Your app wallet public key (starts with `G`)
- PI_APP_SECRET: Your app wallet secret seed (starts with `S`) – treat as a production secret
- PI_NETWORK: `TESTNET` (default) or `MAINNET`
- PI_HORIZON: Horizon base URL (defaults to Pi testnet/mainnet)
- PI_NETWORK_PASSPHRASE: Network passphrase (defaults to `Pi Testnet` / `Pi Network`)

Dev placeholders (ALLOW_DEV_TOKENS=1):

- When Platform calls are unavailable in local/dev, the API may insert placeholder A2U payment IDs that start with `dev-` (e.g. `dev-a2u-<timestamp>`).
- The background payout sweep now detects such IDs and marks them `completed` locally with a synthetic txid, skipping external polling to avoid 404s.
- This behavior is only for development to keep the UI and DB flows testable without a live Platform connection.

## Venue connectors (@hyapi/venues)

The `@hyapi/venues` package exposes normalized yield market data for Aave, JustLend, and Stride using a new Rate schema with base vs reward components.

Exports:
- `aave`, `justlend`, `stride`, plus `Rate`, `RateSchema`.

Rate schema:
```ts
interface Rate {
	venue: 'aave' | 'justlend' | 'stride';
	chain: string;      // chain label (ethereum, tron, cosmos...)
	market: string;     // token / staking derivative symbol
	baseApr: number;    // decimal APR
	baseApy?: number;   // derived APY from baseApr (if computed)
	rewardApr?: number; // incentive APR (optional)
	rewardApy?: number; // incentive APY (optional)
	notes?: string;
	asOf: string;       // ISO timestamp
}
```

Connector interface (simplified):
```ts
interface VenueConnector {
	getLiveRates(markets?: string[]): Promise<Rate[]>;
	estimateApy(rate: Rate, opts?: { compounding?: number; feeBps?: number }): number;
	deposit(args: { amount: number; asset: string; addr?: string }): Promise<string>;   // not implemented yet
	withdraw(args: { amount: number; asset: string; addr?: string }): Promise<string>;  // not implemented yet
}
```

Environment variables:
| Variable | Default | Purpose |
|----------|---------|---------|
| `AAVE_GQL_URL` | `https://api.v3.aave.com/graphql` | Aave GraphQL endpoint |
| `AAVE_GQL_KEY` | (empty) | Optional API key header |
| `JUSTLEND_BASE` | `https://openapi.just.network` | JustLend REST base |
| `STRIDE_STATOM_APR` | `0.12` | Fallback stATOM APR (until LCD integration) |
| `STRIDE_STTIA_APR` | `0.14` | Fallback stTIA APR |

Notes:
* Aave: converts ray liquidityRate -> decimal APR -> daily-compounded APY.
* JustLend: percentage strings to decimals; reward mining APY separated.
* Stride: presently environment fallback for quick iteration (will query LCD later).
* deposit/withdraw: stubs throwing `NOT_IMPLEMENTED` style errors until treasury signer flows added.

Example:
```ts
import { aave } from '@hyapi/venues';

const rates = await aave.getLiveRates(['USDC']);
console.log(rates[0].baseApr, rates[0].baseApy);
```

Planned improvements: add TTL caching (reintroduce with pluggable store), Stride on-chain queries, multi-reward decomposition, and operational deposit/withdraw orchestration.


