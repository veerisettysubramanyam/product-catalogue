import { createApp } from "../../src/app.js";
import { CatalogueService } from "../../src/catalogue/catalogueService.js";
import { StaticCurationProvider, type Curation } from "../../src/catalogue/curation.js";
import type { EmailMessage, EmailSender } from "../../src/email/emailSender.js";
import { EnquiryService } from "../../src/enquiries/enquiryService.js";
import { UpstreamError } from "../../src/http/errors.js";
import { slugify, toDisplayName, type Category, type Product } from "../../src/products/product.js";
import type { ProductRepository } from "../../src/products/productRepository.js";

export function makeProduct(id: string, category: string, overrides: Partial<Product> = {}): Product {
  return {
    id,
    title: `Product ${id}`,
    description: `Description of product ${id}`,
    price: { amount: 10, currency: "USD" },
    category: { slug: slugify(category), name: toDisplayName(category) },
    imageUrl: `https://example.com/${id}.jpg`,
    rating: { average: 3, count: 10 },
    ...overrides,
  };
}

/** In-memory repository used by tests in place of Fake Store. */
export class InMemoryProductRepository implements ProductRepository {
  constructor(private readonly products: Product[]) {}

  async listProducts() {
    return this.products;
  }

  async getProduct(id: string) {
    return this.products.find((p) => p.id === id) ?? null;
  }

  async listCategories(): Promise<Category[]> {
    const map = new Map(this.products.map((p) => [p.category.slug, p.category]));
    return [...map.values()];
  }

  async listProductsInCategory(slug: string) {
    return this.products.filter((p) => p.category.slug === slug);
  }

  async searchProducts(term: string) {
    const needle = term.toLowerCase();
    return this.products.filter((p) =>
      [p.title, p.description, p.category.name].some((t) => t.toLowerCase().includes(needle)),
    );
  }
}

export class FailingProductRepository implements ProductRepository {
  private fail(): never {
    throw new UpstreamError(undefined, { cause: "simulated outage" });
  }
  async listProducts(): Promise<Product[]> {
    this.fail();
  }
  async getProduct(): Promise<Product | null> {
    this.fail();
  }
  async listCategories(): Promise<Category[]> {
    this.fail();
  }
  async listProductsInCategory(): Promise<Product[]> {
    this.fail();
  }
  async searchProducts(): Promise<Product[]> {
    this.fail();
  }
}

export const sampleProducts: Product[] = [
  makeProduct("1", "men's clothing", { title: "Cotton Jacket", rating: { average: 4.7, count: 500 } }),
  makeProduct("2", "men's clothing", { title: "Slim Fit T-Shirt", rating: { average: 4.1, count: 259 } }),
  makeProduct("3", "men's clothing", { title: "Casual Shorts", rating: { average: 2.1, count: 430 } }),
  makeProduct("4", "electronics", { title: "Gaming Drive", description: "Works with PS4" }),
  makeProduct("5", "electronics", { title: "SSD 1TB" }),
  makeProduct("6", "jewelery", { title: "Gold Bracelet", rating: { average: 4.6, count: 400 } }),
  makeProduct("7", "jewelery", { title: "Silver Ring", rating: { average: 1.9, count: 100 } }),
];

export const sampleCuration: Curation = {
  featured: ["6", "1", "4", "999"], // 999 no longer exists and should be skipped
  topRatedByCategory: { "mens-clothing": ["2", "1"] },
};

/** Records emails instead of sending them. Set `failWith` to simulate a provider outage. */
export class RecordingEmailSender implements EmailSender {
  readonly sent: EmailMessage[] = [];
  failWith: Error | null = null;

  async send(message: EmailMessage): Promise<void> {
    if (this.failWith) throw this.failWith;
    this.sent.push(message);
  }
}

export const SALES_INBOX = "sales@test.local";

export function makeTestApp(
  options: {
    repository?: ProductRepository;
    curation?: Curation;
    email?: EmailSender;
    enquiryRateLimitPerMinute?: number;
  } = {},
) {
  const repository = options.repository ?? new InMemoryProductRepository(sampleProducts);
  const catalogue = new CatalogueService(
    repository,
    new StaticCurationProvider(options.curation ?? sampleCuration),
  );
  const enquiries = new EnquiryService(catalogue, options.email ?? new RecordingEmailSender(), SALES_INBOX);
  return createApp(
    { catalogue, enquiries },
    { corsOrigin: "*", enquiryRateLimitPerMinute: options.enquiryRateLimitPerMinute ?? 1000 },
  );
}
