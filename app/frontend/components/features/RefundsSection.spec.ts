import { describe, it, expect, vi, type Mock } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import RefundsSection from "./RefundsSection.vue";
import { buildRefund } from "../../test/fixtures";
import type { Refund } from "../../api/types";

function mountSection(
  opts: { capturedAmount?: number; currency?: string; refunds?: Refund[]; onRefund?: Mock } = {},
) {
  const {
    capturedAmount = 1000,
    currency = "USD",
    refunds = [],
    onRefund = vi.fn().mockResolvedValue(undefined),
  } = opts;
  const wrapper = mount(RefundsSection, {
    props: { capturedAmount, currency, refunds, onRefund },
  });
  return { wrapper, onRefund };
}

describe("RefundsSection", () => {
  it("renders a row per refund with its status badge", () => {
    const { wrapper } = mountSection({
      refunds: [
        buildRefund({ uid: "re_1", amount: 200, status: "succeeded" }),
        buildRefund({ uid: "re_2", amount: 300, status: "pending" }),
      ],
    });

    const rows = wrapper.findAll(".divide-y > div");
    expect(rows).toHaveLength(2);
    expect(wrapper.text()).not.toContain("No refunds yet.");
  });

  it("counts only succeeded refunds against the remaining balance", () => {
    const { wrapper } = mountSection({
      capturedAmount: 1000,
      refunds: [
        buildRefund({ uid: "re_1", amount: 400, status: "succeeded" }),
        buildRefund({ uid: "re_2", amount: 500, status: "pending" }),
        buildRefund({ uid: "re_3", amount: 500, status: "failed" }),
      ],
    });

    expect(wrapper.get("label").text()).toContain("max $6.00");
  });

  it("hides the form and shows Fully refunded. when nothing remains", () => {
    const { wrapper } = mountSection({
      capturedAmount: 1000,
      refunds: [buildRefund({ amount: 1000, status: "succeeded" })],
    });

    expect(wrapper.find("form").exists()).toBe(false);
    expect(wrapper.text()).toContain("Fully refunded.");
  });

  it("converts the entered amount to minor units on submit", async () => {
    const { wrapper, onRefund } = mountSection({ capturedAmount: 1000, currency: "USD" });

    await wrapper.get("input[type=number]").setValue(3);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(onRefund).toHaveBeenCalledWith(300);
  });

  it("shows the error message when the refund rejects", async () => {
    const { wrapper } = mountSection({
      onRefund: vi.fn().mockRejectedValue({ errors: ["amount too high", "try again"] }),
    });

    await wrapper.get("input[type=number]").setValue(3);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(wrapper.get("p.text-red-500").text()).toBe("amount too high, try again");
  });
});
