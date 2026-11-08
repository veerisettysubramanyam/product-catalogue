import { createApp } from "./app.js";
import { CatalogueService } from "./catalogue/catalogueService.js";
import { loadCurationFile } from "./catalogue/curation.js";
import { loadConfig } from "./config.js";
import { FakeStoreProductRepository } from "./products/fakeStoreProductRepository.js";

// Composition root: the only place that knows which concrete implementations are used.
const config = loadConfig();

const products = new FakeStoreProductRepository({
  baseUrl: config.FAKE_STORE_BASE_URL,
  timeoutMs: config.FAKE_STORE_TIMEOUT_MS,
  cacheTtlMs: config.PRODUCT_CACHE_TTL_SECONDS * 1000,
});
const catalogue = new CatalogueService(products, loadCurationFile(config.CURATION_FILE));

const app = createApp({ catalogue }, { corsOrigin: config.CORS_ORIGIN });

app.listen(config.PORT, () => {
  console.log(`Backend listening on http://localhost:${config.PORT}`);
});
