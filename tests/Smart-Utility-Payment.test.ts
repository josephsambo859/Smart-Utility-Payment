
import { describe, expect, it } from "vitest";

describe("Smart-Utility-Payment simnet", () => {
  it("exposes a running simnet environment", () => {
    expect(simnet.blockHeight).toBeDefined();
  });
});
