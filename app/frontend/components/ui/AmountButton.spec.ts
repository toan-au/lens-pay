import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import AmountButton from "./AmountButton.vue";

const base = {
  label: "Capture",
  loadingLabel: "Capturing...",
  currency: "USD",
  loading: false,
};

describe("AmountButton", () => {
  it("shows the loading label and is disabled while loading", () => {
    const wrapper = mount(AmountButton, {
      props: { ...base, amount: 1000, loading: true },
    });
    expect(wrapper.text()).toBe("Capturing...");
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
  });

  it("shows label plus formatted amount when an amount is given", () => {
    const wrapper = mount(AmountButton, { props: { ...base, amount: 1000 } });
    expect(wrapper.text()).toBe("Capture $10.00");
    expect(wrapper.get("button").attributes("disabled")).toBeUndefined();
  });

  it.each([null, undefined])("shows only the label when amount is %s", (amount) => {
    const wrapper = mount(AmountButton, { props: { ...base, amount } });
    expect(wrapper.text()).toBe("Capture");
  });
});
