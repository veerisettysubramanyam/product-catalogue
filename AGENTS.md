# AGENTS.md

Product catalogue PoC: SwiftUI iOS client (`ios/`) + Node/TypeScript backend (`backend/`).
This is meant to grow beyond the PoC. Data source, look and feel and email provider WILL change.

## Boundaries (do not break these)
- The iOS app talks only to our backend. Never call fakestoreapi.com from the client.
- Backend routes never know about Fake Store. Product data comes through the `ProductRepository` interface.
- Email goes through the `EmailSender` interface. No provider-specific code outside its implementation.
- Our API returns our own shapes (domain models), never raw Fake Store JSON.

## Backend rules
- TypeScript strict, no `any`.
- Validate every request input (body, params, query) with zod.
- Config comes from env, parsed once in `src/config.ts`. No secrets in code. Add new vars to `.env.example`.
- Errors go through the central error handler. Never leak stack traces or upstream error bodies.
- Every new endpoint needs a test (vitest + supertest). Tests never hit the real Fake Store or SMTP; use fakes.
- Run `npm test` and `npm run typecheck` before committing.

## iOS rules
- SwiftUI, iOS 17+, MVVM with `@Observable` view models on `@MainActor`.
- async/await only. No third-party packages.
- Views talk only to view models; view models talk to `CatalogueRepository` (a protocol), never to URLSession.
- Decode DTOs, map to app models. Styling lives in `DesignSystem/` so the app can be reskinned.
- Every screen handles loading, error (with retry) and empty states.
- View model changes need a unit test using the mock repository.

## Workflow
- Small, incremental commits with clear messages. Work on the feature branch; never commit to `main`.
- Record assumptions and cut scope in `DECISIONS.md`.
