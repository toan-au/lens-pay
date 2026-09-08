import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";
import DetailCard from "./DetailCard.vue";

describe("DetailCard", () => {
  it("renders its default slot", () => {
    const wrapper = mount(DetailCard, {
      slots: { default: "<p>card body</p>" },
    });
    expect(wrapper.html()).toContain("<p>card body</p>");
  });
});
