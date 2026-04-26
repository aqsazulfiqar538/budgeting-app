# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Rails 8.0 API-only app (Ruby 3.3.0) backed by PostgreSQL. Auth is Devise + devise-jwt (JTI revocation). Pagination via pagy. Rate limiting via rack-attack. Solid Queue / Cache / Cable use the database adapter (no Redis). Tests are RSpec + FactoryBot + shoulda-matchers + SimpleCov.

## Commands

```bash
bin/setup                  # bundle install + db:prepare + start dev server (use --skip-server to skip)
bin/dev                    # dev server (Procfile.dev — currently just rails s)
bin/rails db:prepare       # create + migrate + seed
bin/rails db:reset         # drop + recreate from schema + seed

bundle exec rspec                                # run all specs
bundle exec rspec spec/models/expense_spec.rb    # run a single file
bundle exec rspec spec/models/expense_spec.rb:42 # run a specific line/example

bin/rubocop                # rails-omakase style
bin/brakeman               # security scan
bin/bundler-audit          # gem CVE check
bin/ci                     # full CI pipeline (rubocop + audits + tests)
```

Note: `bin/ci` currently runs `bin/rails test` (Minitest), but the project's tests live under `spec/` and run via RSpec. Use `bundle exec rspec` for the real suite.

## Architecture

### API surface

All routes are under `/api/v1` (see [config/routes.rb](config/routes.rb)). Devise endpoints live at `/api/v1/login`, `/api/v1/signup`, `/api/v1/logout`, etc. JWT is dispatched on `POST /api/v1/log_in` and revoked on `DELETE /api/v1/log_out` (see jwt block in [config/initializers/devise.rb](config/initializers/devise.rb)). 90-day expiry. Rack::Attack throttles login/signup/password-reset and a generic 300 req / 5 min per IP on `/api/`.

[ApplicationController](app/controllers/application_controller.rb) is `ActionController::API`, requires auth by default, and exposes shared helpers every controller uses: `render_success`, `render_error`, `render_paginated(collection, serializer, includes:)`. Prefer these over hand-rolled JSON.

### Domain model

This is an expense-splitting app (think Splitwise). Core graph:

- **User** — Devise + JWT. Has friends (via `Friendship`), groups (via `GroupMembership`), expenses, comments, notifications.
- **Expense** — soft-deleted via `deleted_at`. Belongs to a payer (`user_id`), a category, and optionally a group. `Expense.visible_to(user)` returns expenses where the user is the payer OR a participant. `shared?` means more than one participant.
- **ExpenseParticipant** — join row carrying `paid_share` and `owed_share` per user per expense. `net_balance = owed - paid`.
- **Repayment** — derived debts between two users for a given expense, with `settled` flag. These are *generated* by `ExpenseCreationService`, not entered directly.
- **Friendship** — has a `canonical_ordering` validation: `user_id < friend_id` is required, so always store the lower ID as `user_id`. `requested_by_id` distinguishes who initiated. Statuses: pending / accepted / rejected. Use the `involving(user)` and `accepted` scopes; `User#friends` is built on top of these.
- **Group** — typed (`home`, `trip`, `couple`, `apartment`, `other`). `member?(user)` checks membership.
- **Comment** — has `comment_type` enum (`user_comment`, `system_comment`). The service layer auto-creates a system comment whenever an expense is created.
- **Notification** — polymorphic `source` (Expense / Group / Friendship / etc.), enum `notification_type`.

### Service objects do the heavy lifting

Don't put split/repayment math in controllers or models. Three services own the cross-aggregate logic:

- [ExpenseCreationService](app/services/expense_creation_service.rb) — wraps everything in a transaction, validates group membership and that all participants are friends of the payer, creates the expense, splits it (equal or custom), validates split totals (`paid_share` and `owed_share` must each sum to expense amount for custom splits), generates `Repayment` rows by netting payers vs. owers (proportionally distributing each ower's debt across payers by surplus), creates a system comment, then fires notifications. Raises `ExpenseCreationService::SplitValidationError` on logical errors and rolls back. Equal-split rounding remainder goes to the first participant.
- [LedgerService](app/services/ledger_service.rb) — aggregates unsettled `Repayment` rows into "I owe" / "owed to me" summaries, plus per-friend detail.
- [NotificationService](app/services/notification_service.rb) — single entry point for creating notifications. Always go through this; controllers should not `Notification.create!` directly.

### Controllers, serializers, pagination

Controllers live under `app/controllers/api/v1/`. Custom Devise subclasses (sessions/registrations/passwords/confirmations) override the JSON responses. Use `jsonapi-serializer` classes in `app/serializers/` — pass `include:` for relationships. For lists, use `render_paginated` (returns JSON:API hash + `meta` with pagy info). Default page size is 20 (see [config/initializers/pagy.rb](config/initializers/pagy.rb)).

CORS is open to `ENV["FRONTEND_URL"]` (defaults to `http://localhost:3000`).

### Things that bite

- **Soft deletes**: `Expense.active` scope filters `deleted_at IS NULL`. `Expense.visible_to` already includes it. If you query `Expense` directly, remember to scope.
- **Friendship canonical ordering**: when creating a friendship programmatically, swap so the smaller ID is `user_id` or the validation will reject it.
- **Only the payer** can update/destroy an expense (`authorize_payer!` in `ExpensesController`).
- **Inline group creation**: `POST /api/v1/expenses` accepts `expense[new_group]` to create a group on the fly and add friend-participants to it. See `resolve_group_id` in [app/controllers/api/v1/expenses_controller.rb](app/controllers/api/v1/expenses_controller.rb).
- **Decimals**: `amount`, `paid_share`, `owed_share` are `decimal(12,2)`. Cast strings with `.to_d`, not `.to_f`.

### Testing conventions

- Specs use RSpec (`spec/`), not Minitest (`test/` exists from the Rails generator but is not the active suite).
- FactoryBot syntax methods are auto-included (see [spec/support/factory_bot.rb](spec/support/factory_bot.rb)).
- Shoulda-matchers is wired for `:rails`.
- SimpleCov starts in [spec/spec_helper.rb](spec/spec_helper.rb); coverage lands in `coverage/`.
- Transactional fixtures are on, so factories don't need explicit cleanup.

## Conventions

- Models annotated via the `annotate` gem — schema comments at the top of model files are auto-generated; don't hand-edit them.
- `# frozen_string_literal: true` is the norm on every Ruby file.
- Style is rails-omakase (`bin/rubocop`).
