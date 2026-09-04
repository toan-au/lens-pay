import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import StatusBadge from "./StatusBadge.vue";

describe("StatusBadge", () => {
  it("renders the status text", () => {
    const wrapper = mount(StatusBadge, { props: { status: "succeeded" } });
    expect(wrapper.text()).toBe("succeeded");
  });

  it("applies the class from statusClass for a known status", () => {
    const wrapper = mount(StatusBadge, { props: { status: "succeeded" } });
    expect(wrapper.classes()).toContain("status-badge");
    expect(wrapper.classes()).toContain("status-succeeded");
  });

  it("falls back to the pending class for an unknown status", () => {
    const wrapper = mount(StatusBadge, { props: { status: "wat" } });
    expect(wrapper.classes()).toContain("status-pending");
  });
});
