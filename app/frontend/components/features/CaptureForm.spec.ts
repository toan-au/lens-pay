import { describe, it, expect, vi, type Mock } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import CaptureForm from "./CaptureForm.vue";

function mountForm(opts: { amount?: number; currency?: string; onCapture?: Mock } = {}) {
  const {
    amount = 1000,
    currency = "USD",
    onCapture = vi.fn().mockResolvedValue(undefined),
  } = opts;
  const wrapper = mount(CaptureForm, { props: { amount, currency, onCapture } });
  return { wrapper, onCapture };
}

describe("CaptureForm", () => {
  it("captures the full amount when the field is left blank", async () => {
    const { wrapper, onCapture } = mountForm();

    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(onCapture).toHaveBeenCalledWith(undefined);
  });

  it("converts a partial natural amount to minor units", async () => {
    const { wrapper, onCapture } = mountForm({ currency: "USD" });

    await wrapper.get("input[type=number]").setValue(5);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(onCapture).toHaveBeenCalledWith(500);
  });

  it("does not scale the amount for a zero-decimal currency", async () => {
    const { wrapper, onCapture } = mountForm({ currency: "JPY" });

    await wrapper.get("input[type=number]").setValue(500);
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(onCapture).toHaveBeenCalledWith(500);
  });

  it("shows the error message when the capture rejects", async () => {
    const { wrapper } = mountForm({
      onCapture: vi.fn().mockRejectedValue({ error: "Already captured" }),
    });

    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(wrapper.get("p.text-red-500").text()).toBe("Already captured");
  });

  it("disables the button while pending and clears the field on success", async () => {
    let release!: () => void;
    const { wrapper } = mountForm({
      onCapture: vi.fn().mockReturnValue(new Promise<void>((r) => (release = r))),
    });

    await wrapper.get("input[type=number]").setValue(5);
    await wrapper.get("form").trigger("submit");

    const button = wrapper.get("button");
    expect(button.attributes("disabled")).toBeDefined();
    expect(button.text()).toBe("Capturing...");

    release();
    await flushPromises();

    expect(button.attributes("disabled")).toBeUndefined();
    expect((wrapper.get("input[type=number]").element as HTMLInputElement).value).toBe("");
  });
});
