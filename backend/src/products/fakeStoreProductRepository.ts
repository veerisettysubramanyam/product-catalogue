import { z } from "zod";

import { UpstreamError } from "../http/errors.js";
import { slugify, toDisplayName, type Category, type Product } from "./product.js";
import type { ProductRepository } from "./productRepository.js";

/** Shape we expect from Fake Store. Validated so bad upstream data fails loudly, not deep in the app. */
const fakeStoreProductSchema = z.object({
  id: z.number().int(),
  title: z.string(),
  price: z.number(),
  description: z.string(),
  category: z.string(),
  image: z.string(),
  rating: z.object({ rate: z.number(), count: z.number().int() }).optional(),
});

type FakeStoreProduct = z.infer<typeof fakeStoreProductSchema>;

export interface FakeStoreOptions {
  baseUrl: string;
  timeoutMs: number;
  cacheTtlMs: number;
  fetchFn?: typeof fetch;
  now?: () => number;
}

/**
 * Fake Store only has ~20 products and no search endpoint, so we fetch the full
 * list once, cache it, and derive everything else from it. A real data source
 * would push filtering and search down to the source instead.
 */
export class FakeStoreProductRepository implements ProductRepository {
  private readonly fetchFn: typeof fetch;
  private readonly now: () => number;
  private cache: { expiresAt: number; products: Promise<Product[]> } | null = null;

  constructor(private readonly options: FakeStoreOptions) {
    this.fetchFn = options.fetchFn ?? fetch;
    this.now = options.now ?? Date.now;
  }

  async listProducts(): Promise<Product[]> {
    if (this.cache && this.cache.expiresAt > this.now()) {
      return this.cache.products;
    }

    // Cache the promise so concurrent requests share one upstream call.
    const products = this.fetchAllProducts();
    this.cache = { expiresAt: this.now() + this.options.cacheTtlMs, products };
    try {
      return await products;
    } catch (error) {
      this.cache = null; // don't cache failures
      throw error;
    }
  }

  async getProduct(id: string): Promise<Product | null> {
    const products = await this.listProducts();
    return products.find((product) => product.id === id) ?? null;
  }

  async listCategories(): Promise<Category[]> {
    const products = await this.listProducts();
    const bySlug = new Map<string, Category>();
    for (const product of products) {
      bySlug.set(product.category.slug, product.category);
    }
    return [...bySlug.values()].sort((a, b) => a.name.localeCompare(b.name));
  }

  async listProductsInCategory(categorySlug: string): Promise<Product[]> {
    const products = await this.listProducts();
    return products.filter((product) => product.category.slug === categorySlug);
  }

  async searchProducts(term: string): Promise<Product[]> {
    const needle = term.trim().toLowerCase();
    const products = await this.listProducts();
    if (!needle) return products;
    return products.filter((product) =>
      [product.title, product.description, product.category.name].some((text) =>
        text.toLowerCase().includes(needle),
      ),
    );
  }

  private async fetchAllProducts(): Promise<Product[]> {
    const url = new URL("/products", this.options.baseUrl);
    let response: Response;
    try {
      response = await this.fetchFn(url, {
        headers: { Accept: "application/json" },
        signal: AbortSignal.timeout(this.options.timeoutMs),
      });
    } catch (error) {
      throw new UpstreamError(undefined, { cause: error });
    }

    if (!response.ok) {
      throw new UpstreamError(undefined, { cause: `Fake Store responded ${response.status}` });
    }

    let body: unknown;
    try {
      body = await response.json();
    } catch (error) {
      throw new UpstreamError(undefined, { cause: error });
    }

    const parsed = z.array(fakeStoreProductSchema).safeParse(body);
    if (!parsed.success) {
      throw new UpstreamError(undefined, { cause: parsed.error });
    }
    return parsed.data.map(toProduct);
  }
}

function toProduct(dto: FakeStoreProduct): Product {
  return {
    id: String(dto.id),
    title: dto.title.trim(),
    description: dto.description.trim(),
    price: { amount: dto.price, currency: "USD" },
    category: { slug: slugify(dto.category), name: toDisplayName(dto.category) },
    imageUrl: dto.image,
    rating: { average: dto.rating?.rate ?? 0, count: dto.rating?.count ?? 0 },
  };
}
