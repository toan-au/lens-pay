import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import DetailRow from "./DetailRow.vue";

describe("DetailRow", () => {
  it("renders the label and the default slot", () => {
    const wrapper = mount(DetailRow, {
      props: { label: "Amount" },
      slots: { default: "<span>¥1,000</span>" },
    });
    expect(wrapper.text()).toContain("Amount");
    expect(wrapper.html()).toContain("<span>¥1,000</span>");
  });

  it("applies labelClass to the label element", () => {
    const wrapper = mount(DetailRow, {
      props: { label: "Status", labelClass: "text-red-500" },
    });
    expect(wrapper.get("span").classes()).toContain("text-red-500");
  });

  it("defaults labelClass to empty", () => {
    const wrapper = mount(DetailRow, { props: { label: "Status" } });
    expect(wrapper.get("span").classes()).not.toContain("undefined");
  });
});
