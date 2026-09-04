import { describe, it, expect, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { usePaymentStore } from "./payments";
import * as paymentsApi from "../api/payments";
import { buildPayment, buildRefund } from "../test/fixtures";

vi.mock("../api/payments");

describe("usePaymentStore", () => {
  beforeEach(() => setActivePinia(createPinia()));

  describe("fetchPayments", () => {
    it("replaces the list and stores next_cursor on a first page", async () => {
      const store = usePaymentStore();
      vi.mocked(paymentsApi.listPayments).mockResolvedValue({
        payments: [buildPayment({ uid: "pay_1" })],
        next_cursor: "cur_1",
      });

      await store.fetchPayments({ status: "succeeded" });

      expect(paymentsApi.listPayments).toHaveBeenCalledWith({ status: "succeeded" });
      expect(store.payments.map((p) => p.uid)).toEqual(["pay_1"]);
      expect(store.nextCursor).toBe("cur_1");
    });

    it("appends when a cursor is passed", async () => {
      const store = usePaymentStore();
      store.payments = [buildPayment({ uid: "pay_1" })];
      vi.mocked(paymentsApi.listPayments).mockResolvedValue({
        payments: [buildPayment({ uid: "pay_2" })],
        next_cursor: null,
      });

      await store.fetchPayments({ cursor: "cur_1" });

      expect(store.payments.map((p) => p.uid)).toEqual(["pay_1", "pay_2"]);
      expect(store.nextCursor).toBeNull();
    });
  });

  it("fetchPayment sets currentPayment", async () => {
    const store = usePaymentStore();
    const payment = buildPayment({ uid: "pay_9" });
    vi.mocked(paymentsApi.getPayment).mockResolvedValue(payment);

    await store.fetchPayment("pay_9");

    expect(paymentsApi.getPayment).toHaveBeenCalledWith("pay_9");
    expect(store.currentPayment).toEqual(payment);
  });

  it("submitPayment prepends the created payment and returns it", async () => {
    const store = usePaymentStore();
    store.payments = [buildPayment({ uid: "pay_old" })];
    const created = buildPayment({ uid: "pay_new" });
    vi.mocked(paymentsApi.createPayment).mockResolvedValue(created);

    const result = await store.submitPayment({
      amount: 1000,
      currency: "USD",
      idempotency_key: "idem_1",
    });

    expect(result).toBe(created);
    expect(store.payments.map((p) => p.uid)).toEqual(["pay_new", "pay_old"]);
  });

  it.each([
    ["capture", "capturePayment"],
    ["cancel", "cancelPayment"],
    ["simulateCashPayment", "simulateConfirmation"],
  ] as const)("%s replaces currentPayment with the API result", async (action, apiFn) => {
    const store = usePaymentStore();
    const updated = buildPayment({ uid: "pay_1", status: "succeeded" });
    vi.mocked(paymentsApi[apiFn]).mockResolvedValue(updated);

    await store[action]("pay_1");

    expect(store.currentPayment).toEqual(updated);
  });

  it("fetchRefunds replaces currentRefunds", async () => {
    const store = usePaymentStore();
    vi.mocked(paymentsApi.listRefunds).mockResolvedValue({
      refunds: [buildRefund({ uid: "re_1" })],
    });

    await store.fetchRefunds("pay_1");

    expect(paymentsApi.listRefunds).toHaveBeenCalledWith("pay_1");
    expect(store.currentRefunds.map((r) => r.uid)).toEqual(["re_1"]);
  });

  it("submitRefund prepends the new refund to currentRefunds", async () => {
    const store = usePaymentStore();
    store.currentRefunds = [buildRefund({ uid: "re_old" })];
    vi.mocked(paymentsApi.createRefund).mockResolvedValue(buildRefund({ uid: "re_new" }));

    await store.submitRefund("pay_1", { amount: 500, idempotency_key: "idem_2" });

    expect(paymentsApi.createRefund).toHaveBeenCalledWith("pay_1", {
      amount: 500,
      idempotency_key: "idem_2",
    });
    expect(store.currentRefunds.map((r) => r.uid)).toEqual(["re_new", "re_old"]);
  });

  describe("fetchAllRefunds", () => {
    it("replaces allRefunds and stores the cursor on a first page", async () => {
      const store = usePaymentStore();
      vi.mocked(paymentsApi.listAllRefunds).mockResolvedValue({
        refunds: [buildRefund({ uid: "re_1" })],
        next_cursor: "cur_1",
      });

      await store.fetchAllRefunds({ status: "succeeded" });

      expect(store.allRefunds.map((r) => r.uid)).toEqual(["re_1"]);
      expect(store.allRefundsNextCursor).toBe("cur_1");
    });

    it("appends when a cursor is passed", async () => {
      const store = usePaymentStore();
      store.allRefunds = [buildRefund({ uid: "re_1" })];
      vi.mocked(paymentsApi.listAllRefunds).mockResolvedValue({
        refunds: [buildRefund({ uid: "re_2" })],
        next_cursor: null,
      });

      await store.fetchAllRefunds({ cursor: "cur_1" });

      expect(store.allRefunds.map((r) => r.uid)).toEqual(["re_1", "re_2"]);
      expect(store.allRefundsNextCursor).toBeNull();
    });
  });
});
