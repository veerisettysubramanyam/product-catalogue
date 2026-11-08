import { readFileSync } from "node:fs";

import { z } from "zod";

/**
 * Which products the business has hand-picked as "top rated".
 * This is a business decision, not a property of the product data, so it lives
 * apart from the ProductRepository. Today it's a JSON file; later it could be a
 * CMS or admin screen behind the same CurationProvider interface.
 */
const curationSchema = z.object({
  featured: z.array(z.string().min(1)).max(5),
  topRatedByCategory: z.record(z.string(), z.array(z.string().min(1))).default({}),
});

export type Curation = z.infer<typeof curationSchema>;

export interface CurationProvider {
  getCuration(): Promise<Curation>;
}

export class StaticCurationProvider implements CurationProvider {
  constructor(private readonly curation: Curation) {}

  async getCuration(): Promise<Curation> {
    return this.curation;
  }
}

export function loadCurationFile(path: string): StaticCurationProvider {
  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    throw new Error(`Could not read curation file at ${path}`, { cause: error });
  }
  const parsed = curationSchema.safeParse(raw);
  if (!parsed.success) {
    throw new Error(`Invalid curation file at ${path}: ${parsed.error.message}`);
  }
  return new StaticCurationProvider(parsed.data);
}
