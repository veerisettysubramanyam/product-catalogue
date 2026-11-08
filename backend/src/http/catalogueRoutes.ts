import { Router } from "express";
import { z } from "zod";

import type { CatalogueService } from "../catalogue/catalogueService.js";

const idParam = z.object({ id: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/, "Invalid product id") });
const slugParam = z.object({ slug: z.string().regex(/^[a-z0-9-]{1,64}$/, "Invalid category") });
const searchQuery = z.object({
  search: z.string().trim().max(100, "Search term is too long").optional(),
});

/** List responses are wrapped in { items } so paging metadata can be added later without breaking clients. */
export function catalogueRoutes(catalogue: CatalogueService): Router {
  const router = Router();

  router.get("/products", async (req, res) => {
    const { search } = searchQuery.parse(req.query);
    const items = await catalogue.searchProducts(search ?? "");
    res.json({ items });
  });

  // Must be registered before /products/:id
  router.get("/products/featured", async (_req, res) => {
    res.json({ items: await catalogue.getFeatured() });
  });

  router.get("/products/:id", async (req, res) => {
    const { id } = idParam.parse(req.params);
    res.json(await catalogue.getProduct(id));
  });

  router.get("/categories", async (_req, res) => {
    res.json({ items: await catalogue.listCategories() });
  });

  router.get("/categories/:slug", async (req, res) => {
    const { slug } = slugParam.parse(req.params);
    res.json(await catalogue.getCategoryPage(slug));
  });

  return router;
}
