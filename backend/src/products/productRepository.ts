import type { Category, Product } from "./product.js";

/**
 * The only way the rest of the backend reads product data.
 * Swapping Fake Store for a database, CMS or commerce platform means writing
 * a new implementation of this interface; routes and services don't change.
 *
 * Implementations throw `UpstreamError` when the source is unavailable.
 */
export interface ProductRepository {
  listProducts(): Promise<Product[]>;
  getProduct(id: string): Promise<Product | null>;
  listCategories(): Promise<Category[]>;
  listProductsInCategory(categorySlug: string): Promise<Product[]>;
  /** Case-insensitive match on title, description and category name. */
  searchProducts(term: string): Promise<Product[]>;
}
