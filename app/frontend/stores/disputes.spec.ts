import { describe, it, expect, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { useDisputeStore } from "./disputes";
import * as disputesApi from "../api/disputes";
import { buildDispute, buildDisputeResponse } from "../test/fixtures";

vi.mock("../api/disputes");

describe("useDisputeStore", () => {
  beforeEach(() => setActivePinia(createPinia()));

  describe("fetchDisputes", () => {
    it("replaces the list and stores next_cursor on a first page", async () => {
      const store = useDisputeStore();
      vi.mocked(disputesApi.listDisputes).mockResolvedValue({
        disputes: [buildDispute({ uid: "dp_1" })],
        next_cursor: "cur_1",
      });

      await store.fetchDisputes({ status: "open" });

      expect(disputesApi.listDisputes).toHaveBeenCalledWith({ status: "open" });
      expect(store.disputes.map((d) => d.uid)).toEqual(["dp_1"]);
      expect(store.nextCursor).toBe("cur_1");
    });

    it("appends when a cursor is passed", async () => {
      const store = useDisputeStore();
      store.disputes = [buildDispute({ uid: "dp_1" })];
      vi.mocked(disputesApi.listDisputes).mockResolvedValue({
        disputes: [buildDispute({ uid: "dp_2" })],
        next_cursor: null,
      });

      await store.fetchDisputes({ cursor: "cur_1" });

      expect(store.disputes.map((d) => d.uid)).toEqual(["dp_1", "dp_2"]);
      expect(store.nextCursor).toBeNull();
    });
  });

  describe("fetchDispute", () => {
    it("sets currentDispute and sorts responses newest first", async () => {
      const store = useDisputeStore();
      vi.mocked(disputesApi.getDispute).mockResolvedValue(
        buildDispute({
          uid: "dp_1",
          dispute_responses: [
            buildDisputeResponse({ id: 1, created_at: "2024-01-01T00:00:00Z" }),
            buildDisputeResponse({ id: 3, created_at: "2024-03-01T00:00:00Z" }),
            buildDisputeResponse({ id: 2, created_at: "2024-02-01T00:00:00Z" }),
          ],
        }),
      );

      await store.fetchDispute("dp_1");

      expect(store.currentDispute?.uid).toBe("dp_1");
      expect(store.currentResponses.map((r) => r.id)).toEqual([3, 2, 1]);
    });

    it("handles a dispute with no responses", async () => {
      const store = useDisputeStore();
      vi.mocked(disputesApi.getDispute).mockResolvedValue(
        buildDispute({ dispute_responses: [] }),
      );

      await store.fetchDispute("dp_1");

      expect(store.currentResponses).toEqual([]);
    });

    it("tolerates dispute_responses missing from the payload", async () => {
      const store = useDisputeStore();
      const { dispute_responses: _omit, ...withoutResponses } = buildDispute();
      vi.mocked(disputesApi.getDispute).mockResolvedValue(withoutResponses as never);

      await store.fetchDispute("dp_1");

      expect(store.currentResponses).toEqual([]);
    });
  });

  describe("submitResponse", () => {
    it("prepends the response, re-fetches the dispute, and returns the response", async () => {
      const store = useDisputeStore();
      store.currentResponses = [buildDisputeResponse({ id: 1 })];
      const created = buildDisputeResponse({ id: 2, evidence: { note: "tracking #123" } });
      vi.mocked(disputesApi.respondToDispute).mockResolvedValue(created);
      vi.mocked(disputesApi.getDispute).mockResolvedValue(
        buildDispute({ uid: "dp_1", dispute_responses: [created, buildDisputeResponse({ id: 1 })] }),
      );

      const result = await store.submitResponse("dp_1", { note: "tracking #123" });

      expect(disputesApi.respondToDispute).toHaveBeenCalledWith("dp_1", { note: "tracking #123" });
      expect(disputesApi.getDispute).toHaveBeenCalledWith("dp_1");
      expect(result).toBe(created);
      expect(store.currentResponses.map((r) => r.id)).toEqual([2, 1]);
    });
  });
});
