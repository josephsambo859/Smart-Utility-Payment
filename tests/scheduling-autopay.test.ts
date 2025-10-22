import { describe, expect, it } from "vitest";

/*
  Basic tests for the Bill Scheduling & Auto-Payment feature.
  Tests verify core functionality works correctly.
*/

describe("Bill Scheduling & Auto-Payment Feature", () => {
  it("ensures scheduling functions exist and basic contract is valid", () => {
    // Basic test to ensure the contract compiles and functions exist
    expect(simnet.blockHeight).toBeDefined();
    
    // Test that we can get the next schedule ID (should start at 1)
    const accounts = simnet.getAccounts();
    const address1 = accounts.get("wallet_1")!;
    
    const nextIdResponse = simnet.callReadOnlyFn(
      "Smart-Utility-Payment",
      "get-next-schedule-id",
      [],
      address1
    );
    
    expect(nextIdResponse.result).toEqual("u1");
  });
});
