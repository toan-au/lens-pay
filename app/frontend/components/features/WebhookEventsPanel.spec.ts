import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import WebhookEventsPanel from "./WebhookEventsPanel.vue";
import * as webhookEventsApi from "../../api/webhook_events";
import { buildWebhookEvent } from "../../test/fixtures";

vi.mock("../../api/webhook_events");

async function mountPanel(status: string, events = [buildWebhookEvent()]) {
  vi.mocked(webhookEventsApi.listPaymentWebhookEvents).mockResolvedValue({ webhook_events: events });
  const wrapper = mount(WebhookEventsPanel, { props: { uid: "pay_1", status } });
  await flushPromises();
  return wrapper;
}

describe("WebhookEventsPanel", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("polls once at setup and renders a row per event", async () => {
    const wrapper = await mountPanel("succeeded", [
      buildWebhookEvent({ id: 1, event_type: "payment.succeeded" }),
      buildWebhookEvent({ id: 2, event_type: "refund.succeeded" }),
    ]);

    expect(webhookEventsApi.listPaymentWebhookEvents).toHaveBeenCalledWith("pay_1");
    expect(wrapper.findAll("button")).toHaveLength(2);
    expect(wrapper.text()).toContain("payment.succeeded");
    expect(wrapper.text()).toContain("refund.succeeded");
  });

  it("re-polls every 3s while the payment is not in a terminal status", async () => {
    await mountPanel("processing");
    expect(webhookEventsApi.listPaymentWebhookEvents).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(3000);
    expect(webhookEventsApi.listPaymentWebhookEvents).toHaveBeenCalledTimes(2);

    await vi.advanceTimersByTimeAsync(3000);
    expect(webhookEventsApi.listPaymentWebhookEvents).toHaveBeenCalledTimes(3);
  });

  it("does not schedule another poll once the payment is terminal", async () => {
    await mountPanel("succeeded");

    expect(vi.getTimerCount()).toBe(0);
  });

  it("clears the pending timer on unmount", async () => {
    const wrapper = await mountPanel("processing");
    expect(vi.getTimerCount()).toBe(1);

    wrapper.unmount();

    expect(vi.getTimerCount()).toBe(0);
  });

  it("toggles the payload block when a row is clicked", async () => {
    const wrapper = await mountPanel("succeeded", [
      buildWebhookEvent({ id: 1, payload: { hello: "world" } }),
    ]);

    expect(wrapper.find("pre").exists()).toBe(false);

    await wrapper.get("button").trigger("click");
    expect(wrapper.get("pre").text()).toContain('"hello": "world"');

    await wrapper.get("button").trigger("click");
    expect(wrapper.find("pre").exists()).toBe(false);
  });
});
