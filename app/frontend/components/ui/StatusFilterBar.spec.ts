import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import StatusFilterBar from "./StatusFilterBar.vue";

const tabs = [
  { label: "All", value: "" },
  { label: "Succeeded", value: "succeeded" },
  { label: "Declined", value: "declined" },
];

describe("StatusFilterBar", () => {
  it("renders one button per tab", () => {
    const wrapper = mount(StatusFilterBar, { props: { tabs, modelValue: "" } });
    expect(wrapper.findAll("button")).toHaveLength(3);
    expect(wrapper.text()).toContain("Succeeded");
  });

  it("highlights the button matching modelValue", () => {
    const wrapper = mount(StatusFilterBar, {
      props: { tabs, modelValue: "succeeded" },
    });
    const [all, succeeded] = wrapper.findAll("button");
    expect(succeeded.classes()).toContain("bg-gray-100");
    expect(all.classes()).not.toContain("bg-gray-100");
  });

  it("exposes the active tab via aria-pressed and labels the group", () => {
    const wrapper = mount(StatusFilterBar, {
      props: { tabs, modelValue: "succeeded", label: "Filter payments" },
    });
    const [all, succeeded] = wrapper.findAll("button");
    expect(succeeded.attributes("aria-pressed")).toBe("true");
    expect(all.attributes("aria-pressed")).toBe("false");
    expect(wrapper.get("[role=group]").attributes("aria-label")).toBe("Filter payments");
  });

  it("emits update:modelValue with the clicked tab's value", async () => {
    const wrapper = mount(StatusFilterBar, { props: { tabs, modelValue: "" } });

    await wrapper.findAll("button")[2].trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([["declined"]]);
  });
});
