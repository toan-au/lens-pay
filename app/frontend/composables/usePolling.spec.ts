import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { defineComponent } from "vue";
import { mount } from "@vue/test-utils";
import { usePolling } from "./usePolling";

function mountPolling(fn: () => Promise<boolean>, interval?: number) {
  let polling!: ReturnType<typeof usePolling>;
  const wrapper = mount(
    defineComponent({
      setup() {
        polling = usePolling(fn, interval);
        return () => null;
      },
    }),
  );
  return { wrapper, polling };
}

describe("usePolling", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("does not call fn until one interval has elapsed", async () => {
    const fn = vi.fn().mockResolvedValue(true);
    const { polling } = mountPolling(fn, 2000);

    polling.start();
    expect(fn).not.toHaveBeenCalled();

    await vi.advanceTimersByTimeAsync(2000);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("keeps polling while fn resolves true", async () => {
    const fn = vi.fn().mockResolvedValue(true);
    const { polling } = mountPolling(fn, 1000);

    polling.start();
    await vi.advanceTimersByTimeAsync(3000);

    expect(fn).toHaveBeenCalledTimes(3);
    expect(polling.active.value).toBe(true);
  });

  it("stops when fn resolves false and flips active off", async () => {
    const fn = vi.fn().mockResolvedValue(false);
    const { polling } = mountPolling(fn, 1000);

    polling.start();
    await vi.advanceTimersByTimeAsync(1000);

    expect(fn).toHaveBeenCalledTimes(1);
    expect(polling.active.value).toBe(false);

    await vi.advanceTimersByTimeAsync(5000);
    expect(fn).toHaveBeenCalledTimes(1);
    expect(vi.getTimerCount()).toBe(0);
  });

  it("ignores a second start() while already polling", async () => {
    const fn = vi.fn().mockResolvedValue(true);
    const { polling } = mountPolling(fn, 1000);

    polling.start();
    polling.start();
    await vi.advanceTimersByTimeAsync(1000);

    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("stop() cancels the pending tick", async () => {
    const fn = vi.fn().mockResolvedValue(true);
    const { polling } = mountPolling(fn, 1000);

    polling.start();
    polling.stop();

    expect(polling.active.value).toBe(false);
    await vi.advanceTimersByTimeAsync(5000);
    expect(fn).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("stop() is a no-op when nothing is scheduled", () => {
    const fn = vi.fn().mockResolvedValue(true);
    const { polling } = mountPolling(fn, 1000);

    expect(() => polling.stop()).not.toThrow();
    expect(polling.active.value).toBe(false);
  });

  it("unmounting the component stops polling", async () => {
    const fn = vi.fn().mockResolvedValue(true);
    const { wrapper, polling } = mountPolling(fn, 1000);

    polling.start();
    wrapper.unmount();

    await vi.advanceTimersByTimeAsync(5000);
    expect(fn).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });
});
