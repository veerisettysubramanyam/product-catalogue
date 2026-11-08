# Decisions and assumptions

## Assumptions (where the acceptance criteria were unclear)

| Topic | Assumption | Why |
|---|---|---|
| "I have chosen 5 products to be top rated" | Top rated means **hand-picked by the business**, not Fake Store's customer rating. The 5 IDs live in `backend/config/curation.json`. | "I have chosen" describes a business decision. Keeping curation separate from product data means it survives a change of data source. |
| Top rated on the category page | Each category has its own curated list in the same file. If a category has no picks (for example, a new category appears in the data), it falls back to the 3 highest customer-rated products. | The page is never empty of "top rated", and new categories need no config change to work. |
| "Additional products in that category" | All remaining products in the category, in source order, after the top rated ones (no duplicates). | Simplest reading. |
| Search matching | Case-insensitive substring match on title, description and category name. Done on the backend, because Fake Store has no search endpoint. A blank search is disabled in the app. | "Text matching that search term" is broad, and description matches are useful (for example "ps4"). |
| Enquiry "contact details" | Name and email are required. Phone and message are optional. | Email is enough for sales to reply. Fewer required fields means fewer drop-offs. |
| "Sales inbox will receive an email" | Plain-text email to `SALES_INBOX`, with the customer's address as Reply-To and a reference ID shown to the customer. | Sales can reply directly. The reference ties the thank-you screen to the email. |
| Email provider | SMTP behind an `EmailSender` interface. Locally this is Mailpit; in AWS it would be SES's SMTP endpoint. | The brief rules out paid services and accounts. SMTP is provider-neutral. |
| Currency | USD, the currency Fake Store uses. Prices are sent as `{ amount, currency }`. | Avoids an API change when multi-currency arrives. |
| Product IDs | Strings in our API, even though Fake Store uses numbers. | A real catalogue will likely use SKUs or UUIDs. |
| Product images | The backend returns image URLs and the app loads them directly. Today those URLs are on Fake Store's image host. | All product *data* goes through the backend as required. Images are treated as static assets, which in production would be served by our own CDN (S3 + CloudFront). |
| Platform | iPhone, portrait, iOS 17+. | iOS 17 allows `@Observable`. iPad and landscape add design work without validating the idea. |

## Requirements dropped or simplified

- **No database.** Product data is read from Fake Store and cached in memory for 5 minutes. Enquiries are not stored, only emailed. A PoC doesn't need persistence, and the interfaces leave room to add it.
- **No pagination.** Fake Store has 20 products. List responses are already wrapped in `{ items }` so paging metadata can be added without breaking the app.
- **No admin screen for curation.** It's a JSON file. `CurationProvider` is the seam where a CMS or admin API would plug in.
- **The cache and rate limiter are in memory**, which is fine for one instance. With several instances they'd move to Redis or ElastiCache (or the rate limiting to API Gateway or WAF).
- **No UI tests or snapshot tests.** Unit tests cover view-model behaviour and the API client. The screens were checked by hand in the Simulator.
- **No CI pipeline, no infrastructure-as-code, no deployment.** Only `docker-compose.yml` and a production Dockerfile, which runs on ECS Fargate or App Runner as-is.
- **No localisation, analytics or crash reporting.**
- **No real design.** The look and feel is a clean default, with every colour, spacing and font in `ios/ProductCatalogue/DesignSystem/Theme.swift` so the agency's design can be applied in one place.

## How the design supports growth beyond the PoC

The brief says the **product data source, look and feel, and email provider** will change. Each one is isolated:

| Will change | Where it is isolated | What a change looks like |
|---|---|---|
| Product data source | `ProductRepository` interface in the backend. Routes and services depend only on it. Fake Store's JSON is validated and mapped to our own `Product` model in one file. | Add `PostgresProductRepository` (or a Shopify, Contentful, etc. one) and change one line in `server.ts`. The API contract and the app don't change. Search and filtering can move into the source by implementing `searchProducts` and `listProductsInCategory` there. |
| Look and feel | `DesignSystem/` in the app (`Theme`, `ProductCard`, state views). Screens use theme tokens, not hard-coded styles. | Update `Theme` and the shared components. Screens and view models are untouched. |
| Email provider | `EmailSender` interface. `EnquiryService` builds the message; the sender only delivers it. | Point SMTP at SES (config only), or add an `SesEmailSender` using the AWS SDK. |
| Curation | `CurationProvider` interface, separate from product data. | Replace the JSON file with a CMS or admin API. |
| App ↔ backend contract | The app decodes DTOs and maps them to its own models. Views never see the wire format. | A contract change is handled in `Data/DTOs.swift`. |

Other choices that help the code grow:
- **There is one composition root on each side** (`server.ts` and `AppDependencies`). This is the only place concrete implementations are chosen, which is also why everything is testable with fakes.
- **Errors use one consistent envelope with per-field details**, so new forms get server-side validation feedback in the app for free.
- **Config comes only from env vars**, with a validated schema that fails fast at startup. That fits 12-factor deployment on AWS, with secrets in Secrets Manager or SSM.
- **Security basics:** input validation on every route, a 10 KB body limit, helmet headers, a per-IP rate limit on enquiries, header-injection protection on email fields, and upstream and SMTP errors never leaked to clients. The iOS app only allows plain HTTP to the local network (`NSAllowsLocalNetworking`).

## What I'd do next with another day

1. **Store enquiries** in a database before sending, and send email asynchronously through a queue (SQS) with retries. Today, if SMTP is down the customer sees an error and has to resubmit.
2. **Add a CI pipeline** (GitHub Actions): backend typecheck and tests, iOS build and tests, and a Docker image build.
3. **Deploy to AWS:** backend on App Runner or ECS Fargate behind an ALB, SES for email, CloudFront and S3 for product images, and infrastructure in CDK or Terraform.
4. **Add UI tests** for the critical path (home → product → enquiry → thank you) using XCUITest against a stubbed backend.
5. **Add pagination and sorting** to listing endpoints, and debounced as-you-type search suggestions.
6. **Add bot protection** on the enquiry form (App Attest or a CAPTCHA) on top of the rate limit, plus structured logging and request IDs.
7. **Use an image cache** in the app (AsyncImage doesn't cache aggressively) and add accessibility polish (Dynamic Type review, VoiceOver labels on all actions).
