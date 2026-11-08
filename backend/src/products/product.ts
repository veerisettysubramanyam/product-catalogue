/**
 * Our own product model. The API and the iOS app depend on this shape,
 * never on whatever the current data source returns.
 */
export interface Money {
  amount: number;
  currency: string;
}

export interface Category {
  /** URL-safe identifier, e.g. "mens-clothing". */
  slug: string;
  /** Display name, e.g. "Men's Clothing". */
  name: string;
}

export interface Rating {
  average: number;
  count: number;
}

export interface Product {
  /** String so a future data source can use UUIDs/SKUs without an API change. */
  id: string;
  title: string;
  description: string;
  price: Money;
  category: Category;
  imageUrl: string;
  rating: Rating;
}

export function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/['’]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function toDisplayName(value: string): string {
  return value.replace(/(^|\s)(\S)/g, (_match, space: string, char: string) => space + char.toUpperCase());
}
