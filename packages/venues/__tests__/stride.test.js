import { stride } from "../src/stride";
test("stride getLiveRates returns fallback rates", async () => {
    const rates = await stride.getLiveRates(["stATOM"]);
    expect(Array.isArray(rates)).toBe(true);
    expect(rates[0].venue).toBe("stride");
});
