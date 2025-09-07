import { justlend } from "../src/justlend";
test("justlend getLiveRates returns sane shape", async () => {
    const rates = await justlend.getLiveRates(["USDT", "USDD"]);
    expect(Array.isArray(rates)).toBe(true);
});
