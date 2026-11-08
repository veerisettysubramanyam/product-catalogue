import { describe, expect, it, vi } from "vitest";

import { UpstreamError } from "../src/http/errors.js";
import { FakeStoreProductRepository } from "../src/products/fakeStoreProductRepository.js";

const fakeStoreProducts = [
  {
    id: 1,
    title: "Mens Cotton Jacket",
    price: 55.99,
    description: "Great outerwear for spring",
    category: "men's clothing",
    image: "https://example.com/1.jpg",
    rating: { rate: 4.7, count: 500 },
  },
  {
    id: 2,
    title: "WD 4TB Gaming Drive",
    price: 114,
    description: "Expand your PS4 experience",
    category: "electronics",
    image: "https://example.com/2.jpg",
    rating: { rate: 4.8, count: 400 },
  },
];

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

function makeRepo(fetchFn: typeof fetch, now = () => 0) {
  return new FakeStoreProductRepository({
    baseUrl: "https://fake.test",
    timeoutMs: 1000,
    cacheTtlMs: 60_000,
    fetchFn,
    now,
  });
}

describe("FakeStoreProductRepository", () => {
  it("maps Fake Store products into our domain model", async () => {
    const repo = makeRepo(vi.fn(async () => jsonResponse(fakeStoreProducts)));

    const product = await repo.getProduct("1");

    expect(product).toEqual({
      id: "1",
      title: "Mens Cotton Jacket",
      description: "Great outerwear for spring",
      price: { amount: 55.99, currency: "USD" },
      category: { slug: "mens-clothing", name: "Men's Clothing" },
      imageUrl: "https://example.com/1.jpg",
      rating: { average: 4.7, count: 500 },
    });
  });

  it("returns null for an unknown product", async () => {
    const repo = makeRepo(vi.fn(async () => jsonResponse(fakeStoreProducts)));
    expect(await repo.getProduct("999")).toBeNull();
  });

  it("derives sorted categories and filters by category", async () => {
    const repo = makeRepo(vi.fn(async () => jsonResponse(fakeStoreProducts)));

    expect(await repo.listCategories()).toEqual([
      { slug: "electronics", name: "Electronics" },
      { slug: "mens-clothing", name: "Men's Clothing" },
    ]);
    expect((await repo.listProductsInCategory("electronics")).map((p) => p.id)).toEqual(["2"]);
  });

  it("searches title, description and category case-insensitively", async () => {
    const repo = makeRepo(vi.fn(async () => jsonResponse(fakeStoreProducts)));

    expect((await repo.searchProducts("JACKET")).map((p) => p.id)).toEqual(["1"]);
    expect((await repo.searchProducts("ps4")).map((p) => p.id)).toEqual(["2"]);
    expect((await repo.searchProducts("electronics")).map((p) => p.id)).toEqual(["2"]);
    expect(await repo.searchProducts("no-such-thing")).toEqual([]);
  });

  it("caches the upstream response until the TTL expires", async () => {
    let time = 0;
    const fetchFn = vi.fn(async () => jsonResponse(fakeStoreProducts));
    const repo = makeRepo(fetchFn, () => time);

    await repo.listProducts();
    await repo.getProduct("1");
    await repo.searchProducts("jacket");
    expect(fetchFn).toHaveBeenCalledTimes(1);

    time = 60_001;
    await repo.listProducts();
    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  it("throws UpstreamError on a non-2xx response and does not cache the failure", async () => {
    const fetchFn = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(jsonResponse({}, 500))
      .mockResolvedValueOnce(jsonResponse(fakeStoreProducts));
    const repo = makeRepo(fetchFn);

    await expect(repo.listProducts()).rejects.toBeInstanceOf(UpstreamError);
    expect(await repo.listProducts()).toHaveLength(2);
  });

  it("throws UpstreamError when the request fails or times out", async () => {
    const repo = makeRepo(vi.fn(async () => Promise.reject(new DOMException("timed out", "TimeoutError"))));
    await expect(repo.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });

  it("throws UpstreamError when upstream data has an unexpected shape", async () => {
    const repo = makeRepo(vi.fn(async () => jsonResponse([{ id: "not-a-number" }])));
    await expect(repo.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });
});
