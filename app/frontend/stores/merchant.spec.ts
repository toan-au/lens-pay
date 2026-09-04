import { describe, it, expect, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { useMerchantStore } from "./merchant";
import * as merchantsApi from "../api/merchants";
import { buildMerchant, buildMerchantCreateResponse } from "../test/fixtures";

vi.mock("../api/merchants");

describe("useMerchantStore", () => {
  beforeEach(() => setActivePinia(createPinia()));

  it("is unauthenticated when localStorage has no api_key", () => {
    const store = useMerchantStore();
    expect(store.apiKey).toBeNull();
    expect(store.isAuthenticated).toBe(false);
  });

  it("seeds apiKey from localStorage at creation time", () => {
    localStorage.setItem("api_key", "sk_stored");
    const store = useMerchantStore();
    expect(store.apiKey).toBe("sk_stored");
    expect(store.isAuthenticated).toBe(true);
  });

  it("setApiKey updates the ref and writes localStorage", () => {
    const store = useMerchantStore();
    store.setApiKey("sk_new");
    expect(store.apiKey).toBe("sk_new");
    expect(localStorage.getItem("api_key")).toBe("sk_new");
  });

  it("logout clears the key, merchant, and localStorage", () => {
    localStorage.setItem("api_key", "sk_stored");
    const store = useMerchantStore();
    store.merchant = buildMerchant();

    store.logout();

    expect(store.apiKey).toBeNull();
    expect(store.merchant).toBeNull();
    expect(store.isAuthenticated).toBe(false);
    expect(localStorage.getItem("api_key")).toBeNull();
  });

  it("register stores the returned api_key and returns the full response", async () => {
    const store = useMerchantStore();
    const response = buildMerchantCreateResponse({ api_key: "sk_registered" });
    vi.mocked(merchantsApi.createMerchant).mockResolvedValue(response);

    const result = await store.register({
      name: "Acme",
      email: "owner@acme.test",
      country: "JP",
      currency: "JPY",
    });

    expect(result).toBe(response);
    expect(store.apiKey).toBe("sk_registered");
    expect(localStorage.getItem("api_key")).toBe("sk_registered");
  });

  it("loginAsDemo stores the demo session key", async () => {
    const store = useMerchantStore();
    vi.mocked(merchantsApi.createDemoSession).mockResolvedValue({
      api_key: "sk_demo",
      merchant_uid: "mch_demo",
    });

    await store.loginAsDemo();

    expect(store.apiKey).toBe("sk_demo");
    expect(localStorage.getItem("api_key")).toBe("sk_demo");
  });

  it("fetchMe populates merchant", async () => {
    const store = useMerchantStore();
    const merchant = buildMerchant({ uid: "mch_42" });
    vi.mocked(merchantsApi.getMe).mockResolvedValue(merchant);

    await store.fetchMe();

    expect(store.merchant).toEqual(merchant);
  });

  it("leaves localStorage untouched when register rejects", async () => {
    const store = useMerchantStore();
    vi.mocked(merchantsApi.createMerchant).mockRejectedValue({ error: "email taken" });

    await expect(
      store.register({ name: "Acme", email: "dupe@acme.test", country: "JP", currency: "JPY" }),
    ).rejects.toEqual({ error: "email taken" });

    expect(store.apiKey).toBeNull();
    expect(localStorage.getItem("api_key")).toBeNull();
  });
});
