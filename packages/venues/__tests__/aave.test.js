import { aave } from "../src/aave";
// Simple sanity test; will hit network unless you mock httpJSON.
// For CI, you can stub httpJSON to return a small fixture.
test("aave getLiveRates returns sane shape", async () => {
    const rates = await aave.getLiveRates(["USDT", "USDC"]);
    expect(Array.isArray(rates)).toBe(true);
    if (rates.length) {
        const r = rates[0];
        expect(r.venue).toBe("aave");
        expect(typeof r.baseApr).toBe("number");
    }
});
