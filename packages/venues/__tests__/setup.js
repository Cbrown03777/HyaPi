import { setHttpJSONImpl } from "../src/http";
// Provide a basic mock for tests; individual tests can override by calling setHttpJSONImpl again.
setHttpJSONImpl(async (url, init) => {
    if (typeof url === 'string' && url.includes('aave.com')) {
        return { data: { reserves: [{ symbol: 'USDT', liquidityRate: String(0.05 * 1e27) }] } };
    }
    if (typeof url === 'string' && url.includes('openapi.just.network')) {
        return { code: 0, message: 'ok', data: { tokenList: [{ symbol: 'USDT', supplyApy: '6.5', miningSupplyApy: '1.2' }] } };
    }
    return {};
});
