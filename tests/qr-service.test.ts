import { describe, expect, it } from "vitest";
import { parseHarmonyInvite } from "../mobile/src/services/QRService";

describe("parseHarmonyInvite", () => {
  it("accepts a safe plain room ID", () => {
    expect(parseHarmonyInvite("room_123")).toEqual({ roomId: "room_123" });
  });

  it("extracts room query parameter from invite URL", () => {
    expect(parseHarmonyInvite("https://example.com/join?room=room_123")).toEqual({ roomId: "room_123" });
  });

  it("rejects empty and oversized values", () => {
    expect(parseHarmonyInvite("  ")).toBeNull();
    expect(parseHarmonyInvite("x".repeat(3000))).toBeNull();
  });
});
