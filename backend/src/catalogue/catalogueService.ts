import { NotFoundError } from "../http/errors.js";
import type { Category, Product } from "../products/product.js";
import type { ProductRepository } from "../products/productRepository.js";
import type { CurationProvider } from "./curation.js";

export interface CategoryPage {
  category: Category;
  topRated: Product[];
  others: Product[];
}

/** Used when a category has no hand-picked products (e.g. a new category appears in the data). */
const FALLBACK_TOP_RATED_COUNT = 3;

/**
 * Catalogue use cases. Combines product data (repository) with business
 * curation, so neither the routes nor the data source need to know about both.
 */
export class CatalogueService {
  constructor(
    private readonly products: ProductRepository,
    private readonly curation: CurationProvider,
  ) {}

  async getFeatured(): Promise<Product[]> {
    const [{ featured }, products] = await Promise.all([
      this.curation.getCuration(),
      this.products.listProducts(),
    ]);
    return pickInOrder(products, featured);
  }

  listCategories(): Promise<Category[]> {
    return this.products.listCategories();
  }

  async getCategoryPage(slug: string): Promise<CategoryPage> {
    const categories = await this.products.listCategories();
    const category = categories.find((c) => c.slug === slug);
    if (!category) throw new NotFoundError("Category not found");

    const [{ topRatedByCategory }, products] = await Promise.all([
      this.curation.getCuration(),
      this.products.listProductsInCategory(slug),
    ]);

    const curatedIds = topRatedByCategory[slug] ?? [];
    let topRated = pickInOrder(products, curatedIds);
    if (topRated.length === 0) {
      topRated = [...products]
        .sort((a, b) => b.rating.average - a.rating.average)
        .slice(0, FALLBACK_TOP_RATED_COUNT);
    }

    const topRatedIds = new Set(topRated.map((p) => p.id));
    const others = products.filter((p) => !topRatedIds.has(p.id));

    return { category, topRated, others };
  }

  searchProducts(term: string): Promise<Product[]> {
    return this.products.searchProducts(term);
  }

  async getProduct(id: string): Promise<Product> {
    const product = await this.products.getProduct(id);
    if (!product) throw new NotFoundError("Product not found");
    return product;
  }
}

/** Returns products matching `ids`, in the order of `ids`, skipping ids that no longer exist. */
function pickInOrder(products: Product[], ids: string[]): Product[] {
  const byId = new Map(products.map((p) => [p.id, p]));
  return ids.flatMap((id) => {
    const product = byId.get(id);
    return product ? [product] : [];
  });
}
