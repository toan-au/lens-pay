import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import ResourceTable from "./ResourceTable.vue";

const slots = {
  head: "<th>Name</th>",
  body: "<tr class='row'><td>Alice</td></tr>",
};

describe("ResourceTable", () => {
  it("shows a loading row while loading and still empty", () => {
    const wrapper = mount(ResourceTable, {
      props: { loading: true, isEmpty: true, cols: 3 },
      slots,
    });
    expect(wrapper.text()).toContain("Loading...");
    expect(wrapper.find(".row").exists()).toBe(false);
    expect(wrapper.get("tbody td").attributes("colspan")).toBe("3");
  });

  it("shows the empty slot when empty and not loading", () => {
    const wrapper = mount(ResourceTable, {
      props: { loading: false, isEmpty: true, cols: 2 },
      slots: { ...slots, empty: "<span>No customers yet</span>" },
    });
    expect(wrapper.text()).toContain("No customers yet");
    expect(wrapper.text()).not.toContain("Loading...");
  });

  it("falls back to emptyText when no empty slot is given", () => {
    const wrapper = mount(ResourceTable, {
      props: { loading: false, isEmpty: true, cols: 2, emptyText: "Nothing here" },
      slots,
    });
    expect(wrapper.text()).toContain("Nothing here");
  });

  it("renders the body slot when there is data", () => {
    const wrapper = mount(ResourceTable, {
      props: { loading: false, isEmpty: false, cols: 3 },
      slots,
    });
    expect(wrapper.find(".row").exists()).toBe(true);
    expect(wrapper.text()).toContain("Alice");
    expect(wrapper.text()).not.toContain("Loading...");
  });
});
