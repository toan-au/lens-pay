import { describe, it, expect, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import CustomerPicker from "./CustomerPicker.vue";
import * as customersApi from "../../api/customers";
import { buildCustomer } from "../../test/fixtures";

vi.mock("../../api/customers");

const ALICE = buildCustomer({
  uid: "cus_alice",
  name: "Alice",
  email: "alice@example.com",
});
const BOB = buildCustomer({
  uid: "cus_bob",
  name: "Bob",
  email: "bob@other.test",
});

async function mountPicker(customers = [ALICE, BOB]) {
  vi.mocked(customersApi.listCustomers).mockResolvedValue({
    customers,
    next_cursor: null,
  });
  const wrapper = mount(CustomerPicker);
  await flushPromises();
  return wrapper;
}

describe("CustomerPicker", () => {
  it("loads customers on mount and lists them under Select existing", async () => {
    const wrapper = await mountPicker();

    expect(customersApi.listCustomers).toHaveBeenCalledWith({ limit: 100 });

    await wrapper.get("button").trigger("click");
    expect(wrapper.text()).toContain("Alice");
    expect(wrapper.text()).toContain("Bob");
  });

  it("filters by name or email, case-insensitively", async () => {
    const wrapper = await mountPicker();
    await wrapper.get("button").trigger("click");

    await wrapper.get("input[type=text]").setValue("OTHER");

    expect(wrapper.text()).toContain("Bob");
    expect(wrapper.text()).not.toContain("Alice");
  });

  it("resolve() returns the uid of the picked customer", async () => {
    const wrapper = await mountPicker();
    await wrapper.get("button").trigger("click");

    const aliceButton = wrapper
      .findAll("button")
      .find((b) => b.text().includes("Alice"))!;
    await aliceButton.trigger("click");

    await expect(wrapper.vm.resolve()).resolves.toBe("cus_alice");
  });

  it("resolve() creates a customer from the draft and returns the new uid", async () => {
    const wrapper = await mountPicker([]);
    await wrapper.get("button").trigger("click");
    await wrapper
      .findAll("button")
      .find((b) => b.text() === "Create new")!
      .trigger("click");

    await wrapper.get("input[type=text]").setValue("Carol");
    await wrapper.get("input[type=email]").setValue("carol@example.com");

    const created = buildCustomer({
      uid: "cus_carol",
      name: "Carol",
      email: "carol@example.com",
    });
    vi.mocked(customersApi.createCustomer).mockResolvedValue(created);

    await expect(wrapper.vm.resolve()).resolves.toBe("cus_carol");
    expect(customersApi.createCustomer).toHaveBeenCalledWith({
      name: "Carol",
      email: "carol@example.com",
    });
  });

  it("resolve() returns undefined when no customer is chosen", async () => {
    const wrapper = await mountPicker();

    await expect(wrapper.vm.resolve()).resolves.toBeUndefined();
    expect(customersApi.createCustomer).not.toHaveBeenCalled();
  });

  it("clears a confirmed selection back to the empty state", async () => {
    const wrapper = await mountPicker();
    await wrapper.get("button").trigger("click");
    await wrapper
      .findAll("button")
      .find((b) => b.text().includes("Alice"))!
      .trigger("click");
    expect(wrapper.text()).toContain("alice@example.com");

    await wrapper.get(".bg-gray-50 button").trigger("click");

    expect(wrapper.text()).not.toContain("alice@example.com");
    await expect(wrapper.vm.resolve()).resolves.toBeUndefined();
  });

  it("toggles between the select and create panels", async () => {
    const wrapper = await mountPicker();
    await wrapper.get("button").trigger("click");

    await wrapper
      .findAll("button")
      .find((b) => b.text() === "Create new")!
      .trigger("click");
    expect(wrapper.find("input[type=email]").exists()).toBe(true);

    await wrapper
      .findAll("button")
      .find((b) => b.text() === "Select existing")!
      .trigger("click");
    expect(wrapper.find("input[type=text]").exists()).toBe(true);
    expect(wrapper.find("input[type=email]").exists()).toBe(false);
  });
});
