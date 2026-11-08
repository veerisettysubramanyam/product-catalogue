# Product Catalogue PoC

A product catalogue where customers browse featured products, open categories, search, view product details and send an enquiry that emails the sales team.

- **Client:** iOS app in SwiftUI (`ios/`)
- **Backend:** Node.js + TypeScript, Express (`backend/`)
- **Product data:** [Fake Store API](https://fakestoreapi.com), only ever called by the backend
- **Email:** SMTP. Locally it goes to [Mailpit](https://mailpit.axllent.org), a local inbox you can open in the browser, so there are no accounts or paid services.

Assumptions, cuts and next steps are in [DECISIONS.md](DECISIONS.md). How AI was used is in [AI_USAGE.md](AI_USAGE.md).

## Why iOS + Node/TypeScript

- **iOS (SwiftUI):** it's my main platform, so I can stand behind every line and change it quickly. A native app is also a realistic channel for this kind of business.
- **Node + TypeScript:** it's the preferred backend in the brief. It's quick to stand up, and its typed domain models and zod validation give a clear contract to the app. The backend is deliberately thin: it owns the product data source, the business curation and email delivery, so the app does not have to.

## Architecture

```
 iOS app (SwiftUI)                    Backend (Node/TS)                         External
┌───────────────────────┐   HTTP    ┌────────────────────────────────────┐
│ Views                 │   JSON    │ Routes (validate input, zod)       │
│  └ ViewModels         │ ───────▶  │  └ CatalogueService ─┬─ ProductRepository ──▶ Fake Store API
│     └ Repositories    │           │                      └─ CurationProvider ──▶ config/curation.json
│        └ APIClient    │           │  └ EnquiryService ──── EmailSender ───────▶ SMTP (Mailpit / SES)
└───────────────────────┘           └────────────────────────────────────┘
```

Each arrow on the right is an interface, so the data source, the curation source and the email provider can each be swapped without touching routes or the app. The app depends on our API's shapes, never on Fake Store's.

## Run it locally

### Prerequisites
- Docker Desktop (for the backend and Mailpit)
- Xcode 16 or later (built and tested with Xcode 26), with an iOS 17+ Simulator

### 1. Start the backend and Mailpit

```bash
docker compose up --build
```

- API: http://localhost:3000 (health check at `/health`)
- Mailpit inbox: http://localhost:8025, where enquiry emails arrive

No `.env` is needed. To change settings, `cp .env.example .env` and edit it.

### 2. Run the iOS app

```bash
open ios/ProductCatalogue.xcodeproj
```

Choose the **ProductCatalogue** scheme and any iPhone Simulator (iOS 17+), then press **Run (⌘R)**. The app talks to `http://localhost:3000`, which the Simulator can reach directly.

To point it at a different backend, set the `API_BASE_URL` build setting, or add an `API_BASE_URL` environment variable to the scheme.

### Running the backend without Docker

Needs Node 20+.

```bash
cd backend && npm install && npm run dev
```

By default emails are printed to the console (`EMAIL_TRANSPORT=console`). To use a local SMTP server instead, set `EMAIL_TRANSPORT=smtp` and the `SMTP_*` variables.

## Tests

```bash
cd backend && npm test
```

```bash
cd backend && npm run typecheck
```

```bash
cd ios && xcodebuild test -project ProductCatalogue.xcodeproj -scheme ProductCatalogue -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or press **⌘U** in Xcode. Replace `iPhone 17` with any simulator you have installed.

- **Backend (35 tests):** the Fake Store mapping, caching and failure handling; every endpoint, including curated ordering, search matching, 404/400/502 paths, enquiry validation (including header injection), email failure and rate limiting.
- **iOS (22 tests):** every view model (loading, failure, retry, cancellation, enquiry validation and server errors) and the API client against stubbed HTTP responses.

## API

| Method | Path | Description |
|---|---|---|
| GET | `/api/products/featured` | The 5 hand-picked "top rated" products |
| GET | `/api/categories` | All categories `{ slug, name }` |
| GET | `/api/categories/:slug` | `{ category, topRated, others }` |
| GET | `/api/products?search=term` | Products whose title, description or category match the term (case-insensitive) |
| GET | `/api/products/:id` | One product |
| POST | `/api/enquiries` | `{ productId, name, email, phone?, message? }` → `201 { reference }` and an email to `SALES_INBOX` |

Errors are always `{ "error": { "code", "message", "details?" } }`. Validation errors include per-field `details`, which the app shows next to each field.

## Configuration

All settings are environment variables with safe defaults. See [.env.example](.env.example).

| Variable | Default | Purpose |
|---|---|---|
| `FAKE_STORE_BASE_URL` | `https://fakestoreapi.com` | Product data source |
| `PRODUCT_CACHE_TTL_SECONDS` | `300` | How long product data is cached |
| `CURATION_FILE` | `config/curation.json` | Hand-picked featured and per-category top rated products |
| `EMAIL_TRANSPORT` | `console` (`smtp` in Docker) | `smtp` or `console` |
| `SALES_INBOX` | `sales@example.com` | Where enquiries are sent |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` | Mailpit in Docker | SMTP server |
| `ENQUIRY_RATE_LIMIT_PER_MINUTE` | `5` | Per-IP limit on enquiries |

To change which products are featured, edit [backend/config/curation.json](backend/config/curation.json) and restart.

## Project layout

```
backend/
  src/products/    ProductRepository interface + Fake Store implementation
  src/catalogue/   CatalogueService (featured, category pages) + curation
  src/enquiries/   EnquiryService + validation schema
  src/email/       EmailSender interface + SMTP / console implementations
  src/http/        Express routes and central error handling
  src/server.ts    Composition root (picks the implementations)
  test/            vitest + supertest
ios/
  ProductCatalogue/App/           App entry, navigation, dependency wiring
  ProductCatalogue/Domain/        App models + repository protocols
  ProductCatalogue/Data/          APIClient, DTOs, remote repositories
  ProductCatalogue/Features/      One folder per screen (View + ViewModel)
  ProductCatalogue/DesignSystem/  Theme and shared components (look and feel)
  ProductCatalogueTests/          XCTest unit tests
```
