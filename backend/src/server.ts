import { createApp } from "./app.js";
import { CatalogueService } from "./catalogue/catalogueService.js";
import { loadCurationFile } from "./catalogue/curation.js";
import { loadConfig, type Config } from "./config.js";
import { ConsoleEmailSender } from "./email/consoleEmailSender.js";
import type { EmailSender } from "./email/emailSender.js";
import { SmtpEmailSender } from "./email/smtpEmailSender.js";
import { EnquiryService } from "./enquiries/enquiryService.js";
import { FakeStoreProductRepository } from "./products/fakeStoreProductRepository.js";

// Composition root: the only place that knows which concrete implementations are used.
const config = loadConfig();

const products = new FakeStoreProductRepository({
  baseUrl: config.FAKE_STORE_BASE_URL,
  timeoutMs: config.FAKE_STORE_TIMEOUT_MS,
  cacheTtlMs: config.PRODUCT_CACHE_TTL_SECONDS * 1000,
});
const catalogue = new CatalogueService(products, loadCurationFile(config.CURATION_FILE));
const enquiries = new EnquiryService(catalogue, makeEmailSender(config), config.SALES_INBOX);

const app = createApp(
  { catalogue, enquiries },
  { corsOrigin: config.CORS_ORIGIN, enquiryRateLimitPerMinute: config.ENQUIRY_RATE_LIMIT_PER_MINUTE },
);

app.listen(config.PORT, () => {
  console.log(`Backend listening on http://localhost:${config.PORT} (email transport: ${config.EMAIL_TRANSPORT})`);
});

function makeEmailSender(config: Config): EmailSender {
  if (config.EMAIL_TRANSPORT === "console") return new ConsoleEmailSender();
  return new SmtpEmailSender({
    host: config.SMTP_HOST,
    port: config.SMTP_PORT,
    secure: config.SMTP_SECURE,
    user: config.SMTP_USER,
    pass: config.SMTP_PASS,
    from: config.EMAIL_FROM,
  });
}
