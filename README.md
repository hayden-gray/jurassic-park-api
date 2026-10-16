# Jurassic Park API

JSON REST API for tracking the park's cages and the dinosaurs in them.

## Stack

- Ruby 3.4.4, Rails 8.1 (API mode)
- PostgreSQL
- RSpec + FactoryBot

## Setup

```sh
bundle install
bin/rails db:create db:migrate db:seed   # seed loads the eight species from the spec
bundle exec rspec
bin/rails server
```

## API

| Method | Path | Notes |
|--------|------|-------|
| GET | `/species` | Use it to find a `species_id`. |
| POST | `/species` | `name`, `diet` (`herbivore` or `carnivore`) |
| PATCH | `/species/:id` | `name` only. Diet can't change once created. |
| DELETE | `/species/:id` | Only when no dinosaurs use it |
| GET | `/cages` | Filters: `id`, `power_status` |
| GET | `/cages/:id` | Includes `dinosaur_count` |
| POST | `/cages` | `capacity` (required), `power_status` (`ACTIVE` by default) |
| PATCH | `/cages/:id` | `capacity`, `power_status` |
| DELETE | `/cages/:id` | Only when the cage is empty |
| GET | `/dinosaurs` | Filters: `id`, `species_id`, `cage_id` |
| GET | `/dinosaurs/:id` | Includes the species name and diet |
| POST | `/dinosaurs` | `name`, `species_id` (required), `cage_id` (optional) |
| PATCH | `/dinosaurs/:id` | `name`, `cage_id` (blank removes it from its cage). Species can't change. |
| DELETE | `/dinosaurs/:id` | |

Examples:

```sh
curl -X POST localhost:3000/cages -d capacity=2
curl -X POST localhost:3000/dinosaurs -d name=Blue -d species_id=2 -d cage_id=1
curl -g "localhost:3000/dinosaurs?filter[cage_id]=1"
curl -g "localhost:3000/cages?filter[power_status]=DOWN"
```

**Responses.** Success returns the resource itself (or an array). Errors return
`{ "errors": { "field": ["message"] } }` with `404` for a missing record and `422` for any rule
failure (invalid input, a full cage, a powered-down cage, a species conflict, powering off an
occupied cage, and so on).

**Filters.** Filters go in a `filter[...]` param and take a single value. An unknown filter name or a
list value is a `422`; an unknown *value* returns an empty list. To add a filter, add its column to
the `FILTERS` constant at the top of the controller.

## Business rules

- A dinosaur needs a name and a species. Carnivores only share a cage with their own species;
  herbivores never share with carnivores.
- Cages have a capacity and a power status (`ACTIVE` or `DOWN`). A cage can't be powered off while it
  holds dinosaurs, a dinosaur can't be moved into a `DOWN` cage, and capacity can't drop below the
  current number of dinosaurs.
- Cage placement lives in one place, `app/services/cage_assignment.rb`.

## Design decisions

- **Integrity in the database where possible, and in the models for friendly errors.** Required
  columns, foreign keys, and CHECK constraints (capacity > 0, valid power status, valid diet, non-blank
  name) back up the model validations, so bad data is rejected even if the app is bypassed.
- **Species is a table with a diet**, not a constant. Adding a species is a `POST`, not a deploy, and the
  diet lives in one place. A species' diet is fixed once created, so existing cages can't silently become invalid. A dinosaur's JSON includes its species name and diet.
- **A dinosaur may exist without a cage** (`cage_id` is nullable), so vet visits and transport don't need
  a fake cage.
- **Cage occupancy is a `COUNT`**, not a stored counter, so it can't drift out of sync.
- **Placement rules are a service object.** They're the core business logic, so they sit in one named
  place with one entry point. The controllers never hand `cage_id` to the model.
- **Bare JSON responses, no envelope.** Simple for clients, and the status code carries success or failure.
  Adding metadata later (such as pagination totals) would change the response shape, so it would need
  API versioning.
- **`power_status` is a plain attribute** updated with `PATCH`, not separate power-on and power-off
  endpoints. Output is always `ACTIVE`/`DOWN`; input also accepts lowercase.
- **Errors are centralized** in `ApplicationController` (`rescue_from`), so controllers only handle the
  success path.

## Running in a concurrent environment

The placement rules are check-then-write: read the cage's contents, decide, then save. Two requests at
once could both see "one slot left" and both take it, or one request could power a cage down while another
places a dinosaur in it. The database can't prevent that (the rules span rows), so:

- `CageAssignment` runs in a transaction and loads the cage with a row lock (`SELECT ... FOR UPDATE`).
  Requests for the same cage queue up; requests for different cages don't affect each other.
- Updating or deleting a cage takes the same lock (`with_lock`), so power-off, capacity changes, and
  deletes can't interleave with a placement.
- The lock is released when the transaction commits or rolls back.
- `spec/services/cage_assignment_concurrency_spec.rb` races two requests for the last slot. It fails
  without the lock and passes with it.

Trade-offs and limits:

- Only writes that go through the service or the cage controller are protected. Writing `cage_id`
  directly (console, seeds, another service) bypasses both the rules and the lock.
- There is no lock timeout, so a stuck transaction would make other requests for that cage wait. I'd set
  a `lock_timeout` in production.
- Locking one cage is simple. An operation that locked two cages would need a consistent lock order to
  avoid deadlocks; moving a dinosaur only locks the destination cage today.

## Not completed / known gaps

- **No pagination.** `GET /cages` and `GET /dinosaurs` return every matching row.
- **A dinosaur's species and a species' diet can't be changed** after creation. A mistyped one means delete and re-create (a species only while no dinosaurs use it).
- **Duplicate species names** are rejected by a validation and a unique index, but two simultaneous creates could hit the index and return a 500 instead of a 422.
- **No authentication or authorization.** The spec mentions builders, doctors, and scientists, but it doesn't
  define roles, so I didn't invent any.
- **Filters** are exact-match on one value. A typo in a filter *value* looks the same as "no matches".
- The cage index loads each cage's dinosaurs to compute `dinosaur_count`, which is fine at this size.
- CI runs RuboCop, Brakeman, and bundler-audit but not the specs.

## What I would do with more time

- **Pagination** for both index endpoints. I'd start with `page`/`per_page` and metadata in headers (so the
  response body stays an array and nothing breaks), and move to keyset pagination if tables got large.
- **Performance:** benchmark the list endpoints and the placement path with realistic data (thousands of
  cages and dinosaurs), check query plans, and compute `dinosaur_count` with a SQL `COUNT` instead of
  loading rows. Measure lock contention on a busy cage.
- **Tenant scoping** (for example by site or account) and authentication, so thousands of cages are
  partitioned and access is controlled.
- **More filtering and sorting:** multiple values per filter, sorting, and stricter validation of filter
  values.
- **Concurrency:** a lock timeout, retries on lock failure, and optionally idempotency keys to
  stop double-submitted creates.
- **API versioning** before any change to the response shape, and a hosted API doc (OpenAPI).
- **Soft deletes or an audit trail** for cages and dinosaurs.
- **CI** with an RSpec job (it currently runs lint and security scans only).
