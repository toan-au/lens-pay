import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import ApiKeyDisplay from "./ApiKeyDisplay.vue";

const KEY = "lp_test_abcdefghijklmnopqrstuvwxyz";

describe("ApiKeyDisplay", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("starts masked with a Show button", () => {
    const wrapper = mount(ApiKeyDisplay, { props: { apiKey: KEY } });
    expect(wrapper.get("code").text()).toBe(`lp_${"*".repeat(24)}`);
    expect(wrapper.get("button").text()).toBe("Show");
    expect(wrapper.text()).not.toContain(KEY);
  });

  it("reveals the full key on the first click", async () => {
    const wrapper = mount(ApiKeyDisplay, { props: { apiKey: KEY } });
    await wrapper.get("button").trigger("click");
    expect(wrapper.get("code").text()).toBe(KEY);
    expect(wrapper.get("button").text()).toBe("Copy");
  });

  it("copies to the clipboard and shows Copied! on the second click", async () => {
    const wrapper = mount(ApiKeyDisplay, { props: { apiKey: KEY } });
    await wrapper.get("button").trigger("click");
    await wrapper.get("button").trigger("click");

    expect(vi.mocked(navigator.clipboard.writeText)).toHaveBeenCalledWith(KEY);
    expect(wrapper.get("button").text()).toBe("Copied!");
  });

  it("reverts to Copy after 2 seconds", async () => {
    const wrapper = mount(ApiKeyDisplay, { props: { apiKey: KEY } });
    await wrapper.get("button").trigger("click");
    await wrapper.get("button").trigger("click");
    expect(wrapper.get("button").text()).toBe("Copied!");

    await vi.advanceTimersByTimeAsync(2000);
    expect(wrapper.get("button").text()).toBe("Copy");
  });

  it("masks with no prefix when the key has no underscore", () => {
    const wrapper = mount(ApiKeyDisplay, { props: { apiKey: "plainkey" } });
    expect(wrapper.get("code").text()).toBe("*".repeat(24));
  });
});
