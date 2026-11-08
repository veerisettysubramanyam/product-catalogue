import request from "supertest";
import { describe, expect, it } from "vitest";

import { FailingProductRepository, makeTestApp } from "./support/fakes.js";

const ids = (items: Array<{ id: string }>) => items.map((p) => p.id);

describe("catalogue API", () => {
  const app = makeTestApp();

  describe("GET /api/products/featured", () => {
    it("returns the curated products in curated order, skipping missing ones", async () => {
      const res = await request(app).get("/api/products/featured");
      expect(res.status).toBe(200);
      expect(ids(res.body.items)).toEqual(["6", "1", "4"]);
    });
  });

  describe("GET /api/categories", () => {
    it("lists categories", async () => {
      const res = await request(app).get("/api/categories");
      expect(res.status).toBe(200);
      expect(res.body.items).toContainEqual({ slug: "mens-clothing", name: "Men's Clothing" });
    });
  });

  describe("GET /api/categories/:slug", () => {
    it("returns curated top rated first, then the remaining products", async () => {
      const res = await request(app).get("/api/categories/mens-clothing");
      expect(res.status).toBe(200);
      expect(res.body.category).toEqual({ slug: "mens-clothing", name: "Men's Clothing" });
      expect(ids(res.body.topRated)).toEqual(["2", "1"]);
      expect(ids(res.body.others)).toEqual(["3"]);
    });

    it("falls back to highest customer rating when nothing is curated", async () => {
      const res = await request(app).get("/api/categories/jewelery");
      expect(ids(res.body.topRated)).toEqual(["6", "7"]);
      expect(res.body.others).toEqual([]);
    });

    it("404s for an unknown category", async () => {
      const res = await request(app).get("/api/categories/garden");
      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe("not_found");
    });

    it("400s for a malformed slug", async () => {
      const res = await request(app).get("/api/categories/Bad%20Slug!");
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("validation_failed");
    });
  });

  describe("GET /api/products?search=", () => {
    it("only returns products whose text matches the term", async () => {
      const res = await request(app).get("/api/products").query({ search: "ps4" });
      expect(res.status).toBe(200);
      expect(ids(res.body.items)).toEqual(["4"]);
    });

    it("matches on category name too", async () => {
      const res = await request(app).get("/api/products").query({ search: "jewel" });
      expect(ids(res.body.items)).toEqual(["6", "7"]);
    });

    it("returns an empty list when nothing matches", async () => {
      const res = await request(app).get("/api/products").query({ search: "zzz" });
      expect(res.status).toBe(200);
      expect(res.body.items).toEqual([]);
    });

    it("rejects overly long search terms", async () => {
      const res = await request(app).get("/api/products").query({ search: "a".repeat(101) });
      expect(res.status).toBe(400);
    });
  });

  describe("GET /api/products/:id", () => {
    it("returns the product", async () => {
      const res = await request(app).get("/api/products/4");
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ id: "4", title: "Gaming Drive", category: { slug: "electronics" } });
    });

    it("404s for an unknown product", async () => {
      const res = await request(app).get("/api/products/999");
      expect(res.status).toBe(404);
    });
  });

  describe("when the product source is down", () => {
    const brokenApp = makeTestApp({ repository: new FailingProductRepository() });

    it("returns a clean 502 without leaking internals", async () => {
      const res = await request(brokenApp).get("/api/products/featured");
      expect(res.status).toBe(502);
      expect(res.body).toEqual({
        error: { code: "upstream_unavailable", message: "Product data is temporarily unavailable" },
      });
    });
  });
});
