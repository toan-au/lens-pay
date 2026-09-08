import { beforeEach, vi } from "vitest";

beforeEach(() => {
  localStorage.clear();
});

if (!navigator.clipboard) {
  Object.defineProperty(navigator, "clipboard", {
    configurable: true,
    value: { writeText: vi.fn().mockResolvedValue(undefined) },
  });
}
