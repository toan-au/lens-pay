import { beforeEach, vi } from "vitest";

process.env.TZ ??= "UTC";

beforeEach(() => {
  localStorage.clear();
});

if (!globalThis.crypto?.randomUUID) {
  const cryptoObj = (globalThis.crypto ??= {} as Crypto);
  Object.defineProperty(cryptoObj, "randomUUID", {
    configurable: true,
    value: () => "00000000-0000-4000-8000-000000000000",
  });
}

if (!navigator.clipboard) {
  Object.defineProperty(navigator, "clipboard", {
    configurable: true,
    value: { writeText: vi.fn().mockResolvedValue(undefined) },
  });
}
