# AI usage

I built this with an AI coding agent doing most of the typing, and spent my own effort on deciding what to build, setting the rules, reviewing the output and checking that it actually works.

## Tools and models

| Tool | What I used it for |
|---|---|
| **Claude Code** (desktop app), model **Claude Opus 5.5** | Understanding the brief, planning, writing the backend, the iOS app, the tests and the docs, running the tests, and driving the iOS Simulator to check each flow |
| Xcode 26.6 + iOS Simulator (iPhone 17 Pro, iOS 26.4) | Building, running and testing the iOS app |
| Node 24, npm, vitest | Running and testing the backend |
| Docker (via Colima) + Docker Compose | Checking the reviewer's `docker compose up` path end to end |
| GitHub CLI | Pushing the branch and opening the PR |

No other AI tools were used.

## Agent instruction file

[AGENTS.md](AGENTS.md) is committed at the repo root. It was the first commit, written before any code, and it set the rules the agent had to follow:

- **Boundaries:** the app only talks to our backend; routes never know about Fake Store; email only goes through the `EmailSender` interface; the API returns our own shapes, never raw Fake Store JSON.
- **Backend:** strict TypeScript with no `any`, zod validation on every input, config only from env vars, every endpoint tested with fakes (never the real Fake Store or SMTP).
- **iOS:** SwiftUI, iOS 17+, MVVM with `@Observable`, async/await, no third-party packages, view models talk to repository protocols, every screen handles loading, error and empty states.
- **Workflow:** small incremental commits on the feature branch; record assumptions in DECISIONS.md.

It started out as `CLAUDE.md` (the file Claude Code reads automatically) and I renamed it to `AGENTS.md`, the tool-neutral name, before opening the PR.

## Plan and spec

I didn't let the agent write code until the plan was agreed.

**1. Understand the brief.** I had the agent read the PDF and summarise what's required: the five features, the hard constraints (client never calls Fake Store, runs locally in under 10 minutes, no secrets, no paid services) and the deliverables.

**2. Choose the stack.** I'm an iOS developer, so I picked **SwiftUI** for the client. The brief makes a backend mandatory (product data must go through it, and the email needs a server), so I picked **Node + TypeScript**, the preferred option, and kept it thin.

**3. Spec the design around what the brief says will change** (data source, look and feel, email provider):

| Will change | Put behind |
|---|---|
| Product data source | `ProductRepository` interface (backend) |
| Email provider | `EmailSender` interface; SMTP, with Mailpit locally so no accounts are needed |
| Look and feel | `DesignSystem/Theme` (iOS) |
| "Top rated" picks | `CurationProvider`, a JSON file for now |

**4. Spec the API:** `GET /api/products/featured`, `GET /api/categories`, `GET /api/categories/:slug`, `GET /api/products?search=`, `GET /api/products/:id`, `POST /api/enquiries`.

**5. Agree the build order, one commit per step:** agent rules → backend scaffold → product repository → catalogue endpoints → enquiry + email → Docker → iOS foundation → iOS screens → iOS tests → docs → PR.

The assumptions made along the way (for example, "top rated" means hand-picked by the business) are in [DECISIONS.md](DECISIONS.md).

## Key prompts and moments

**1. Understand before building.**
> "explain me what has to be done in the assignment first, then let us decide what to do and how to do?"

This kept the first part of the work to reading and planning, and surfaced the constraints that shaped everything else.

**2. Deciding whether I needed a backend at all.**
> "I am an iOS developer, so if i build the app, is it fine or should i build backend also for this."

The answer was that the backend is mandatory: the brief forbids calling Fake Store from the client, and an app can't safely send email itself. That settled the iOS + Node/TypeScript split and kept the backend deliberately small.

**3. Setting how the work should be done.**
> "while commiting be careful, i want incremental commits only and follow the instructions strictly given in the assignment."

This is why the history is 11 small commits, each building and passing its tests before the next one started, and why the agent kept checking the brief's constraints (no secrets, `.env.example`, no paid services, the PR left open).

**4. Reviewing the architecture myself.**
> "in iOS app, are the viewmodels, repositories and apiclients reusable? i.e do they depend on protocols or you made them to depend on concrete types."

This found a real gap (see the first item in the next section) and led to the `HTTPClient` protocol refactor plus 8 new repository tests.

**5. Refusing to accept an unverified setup path.**
> "okay, install docker yourself."

The `docker compose` setup had been written but never run, because Docker wasn't installed on my machine. Once it was installed, we ran exactly what the reviewer will run, confirmed both containers were healthy, and confirmed that an enquiry email arrived in Mailpit.

## Where the AI got things wrong, and how I caught it

**1. Repositories depended on a concrete type.** The view models correctly depended on repository protocols, but the repositories took the concrete `APIClient`. That meant they could only be tested through a stubbed `URLProtocol`, and changing the transport meant editing `APIClient` itself.
- *Caught by:* me, asking directly whether each layer depended on protocols.
- *Fix:* an `HTTPClient` protocol that `APIClient` conforms to, a mock client that decodes canned JSON with the real DTOs, and 8 repository tests.

**2. The one-command setup was documented but not proven.** The agent wrote the Dockerfile, `docker-compose.yml` and README instructions, but couldn't run them because Docker wasn't installed. To its credit, it said so. Still, I wasn't going to submit setup steps nobody had run.
- *Caught by:* the agent's own note, which I followed up on.
- *Fix:* installed Docker (Colima), ran `docker compose up --build`, and checked the health endpoint, the featured products and an enquiry email arriving in Mailpit.

**3. A view referenced a property that didn't exist.** The first version of the enquiry form's toolbar used `viewModel.submittedReference`, which was never defined. That's a classic AI "looks right" line.
- *Caught by:* the agent itself, re-reading the file before the first build, so it never reached a commit. The compiler would have rejected it anyway; it's a reminder that AI output needs a build and a read, not just a glance.
- *Fix:* replaced with a simple `isSubmitted` property on the view model.

**4. Product images still come from Fake Store's host.** All product *data* goes through the backend as required, but the image URLs the backend passes on still point at Fake Store's image server, so the app loads images from there. This wasn't considered in the first design.
- *Caught by:* noticed while checking the app in the Simulator.
- *Decision:* treated images as static assets rather than API data, documented it in DECISIONS.md and the PR as a known gap, with the production answer being our own CDN. I chose not to proxy images through the backend for a PoC.

**5. Attribution I didn't want.** By default the agent added a co-author line naming itself to every commit and named the instruction file after the tool.
- *Caught by:* me, reviewing the commit history before pushing.
- *Fix:* rewrote the commit messages and renamed the file to `AGENTS.md`, before anything was pushed. This document is where the AI use is disclosed.

## Time spent

| Phase | What it covered | Time |
|---|---|---|
| Planning | Reading the brief, understanding the requirements, choosing iOS + Node, agreeing assumptions and the build order (7–8 Nov) | ~30 min |
| Building | Backend and iOS app, 10 commits (8 Nov, 12:09–12:25) | ~25 min |
| Testing | Running both test suites, checking every flow in the iOS Simulator, installing Docker and verifying `docker compose` end to end | ~20 min |
| Reviewing | Reviewing the architecture (which led to the `HTTPClient` refactor), cleaning the commit history, writing the PR, and reading through the code | ~60 min |
| **Total** | | **~2 h 15 min** |

The build itself was fast because the plan and rules were settled first and the agent did the typing. Most of my own time went into planning, reviewing and verifying, which is where I think the judgement in this exercise sits.
