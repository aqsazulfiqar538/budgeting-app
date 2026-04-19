# QA, Code Review & Best Practices Reference

> Use this document to audit the app before each release or when onboarding new developers.

---

## 1. API Response Standards

### Success Responses

**Single resource:**
```json
{
  "data": {
    "id": "1",
    "type": "expense",
    "attributes": { ... },
    "relationships": { ... }
  },
  "included": [ ... ]
}
```

**Collection (paginated):**
```json
{
  "data": [ ... ],
  "included": [ ... ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20,
    "next_page": 2,
    "prev_page": null
  }
}
```

**Action success (no data):**
```json
{ "message": "Action completed successfully." }
```

**Delete:** Returns `204 No Content` with no body.

### Error Responses

**All errors use the same format:**
```json
{ "errors": ["Error message 1", "Error message 2"] }
```

**Status codes:**
| Code | When |
|------|------|
| 200 | Success |
| 201 | Created |
| 204 | Deleted (no body) |
| 401 | Unauthorized (no token or invalid token) |
| 404 | Record not found |
| 422 | Validation errors |
| 429 | Rate limit exceeded |
| 500 | Server error (should never happen in production) |

### Rules
- Always return `{ errors: [] }` for failures — never `{ error: "..." }` (singular)
- Use `render_error(errors)` helper from ApplicationController
- Use `render_paginated(collection, Serializer, includes: [...])` for list endpoints
- Use JSONAPI serializers for all resource responses — never raw `render json: model`

---

## 2. Pagination

**Gem:** `pagy ~> 9.0`
**Default:** 20 items per page

### Usage in controllers
```ruby
# In any index action:
render_paginated(collection, ExpenseSerializer, includes: [:category])

# Custom per_page:
pagy, records = pagy(collection, limit: 10)
```

### Frontend consumption
```
GET /api/v1/expenses?page=2
GET /api/v1/expenses?page=2&limit=10
```

Response includes `meta` object with pagination info. Frontend should use `meta.next_page` and `meta.prev_page` for navigation.

---

## 3. Authentication (Devise + JWT)

### Token Flow
1. `POST /api/v1/login` → JWT token in `Authorization` response header
2. All subsequent requests include `Authorization: Bearer <token>` header
3. Token expires in 90 days (configurable in `config/initializers/devise.rb`)
4. `DELETE /api/v1/logout` revokes the token

### Confirmable
- New users must confirm email before logging in
- Confirmation token sent via email (letter_opener in dev)
- `GET /api/v1/confirmation?confirmation_token=X` to confirm

### Password Reset
- `POST /api/v1/password` with `{ user: { email } }` to send reset email
- `PATCH /api/v1/password` with `{ user: { reset_password_token, password, password_confirmation } }`

### Key Files
- `config/initializers/devise.rb` — JWT config, mailer sender, token expiry
- `app/controllers/api/v1/sessions_controller.rb` — login/logout
- `app/controllers/api/v1/registrations_controller.rb` — signup
- `app/controllers/api/v1/passwords_controller.rb` — forgot/reset password
- `app/controllers/api/v1/confirmations_controller.rb` — email confirmation

---

## 4. Security Checklist

### Rate Limiting (Rack::Attack)
- Login: 5 attempts per IP per 60 seconds
- Signup: 3 attempts per IP per 60 seconds
- Password reset: 3 attempts per IP per 60 seconds
- General API: 300 requests per IP per 5 minutes
- Returns 429 with `Retry-After` header when throttled
- Config: `config/initializers/rack_attack.rb`

### CORS
- Configured in `config/initializers/cors.rb`
- Default: `http://localhost:3001` (React dev server)
- Set `FRONTEND_URL` env var for production
- Exposes `Authorization` header for JWT

### Authorization
- All expenses scoped to `current_user` — users cannot access others' data
- Category ownership validated — users cannot use other users' custom categories
- Category parent ownership validated — users cannot nest under other users' categories
- `rescue_from ActiveRecord::RecordNotFound` returns 404, not 500

### Input Validation
- Strong params on all controllers
- Model validations on all required fields
- Custom validations for cross-field rules (end_date > start_date, category accessibility)

---

## 5. N+1 Query Prevention

### Rules
- Always use `includes()` when serializing relationships
- Use `render_paginated` which auto-loads the collection
- Check Rails logs for `SELECT` queries inside loops

### Current Patterns
```ruby
# Expenses with category — always eager load
current_user.expenses.filter_by(...) # includes(:category) built into scope
ExpenseSerializer.new(expenses, include: [:category])

# Categories with subcategories — eager loaded
Category.for_user(current_user).active.top_level.includes(:subcategories).sorted
```

### How to Audit
```bash
# In rails console, enable query logging:
ActiveRecord::Base.logger = Logger.new(STDOUT)
# Then call your endpoint and watch for repeated SELECT statements
```

---

## 6. DRY Patterns

### ApplicationController helpers
```ruby
render_error(errors, status: :unprocessable_entity)  # Consistent error format
render_success(data, status: :ok, message: "Done")   # Consistent success format
render_paginated(collection, Serializer, includes: []) # Paginated JSONAPI response
not_found  # Automatic via rescue_from
```

### Model scopes
- Keep filtering logic in model scopes, not controllers
- Scopes should be composable (chainable)
- Use keyword arguments for clarity: `filter_by(category_id:, start_date:, end_date:)`

### Serializers
- One serializer per model
- Always declare `has_many` / `belongs_to` relationships
- Use `include: [...]` in controllers to control what's loaded

---

## 7. Code Style

### File Headers
- All Ruby files should have `# frozen_string_literal: true`

### Naming
- Controllers: `Api::V1::ExpensesController` (namespaced)
- Models: `Expense` (singular)
- Serializers: `ExpenseSerializer`
- Scopes: descriptive verbs (`filter_by`, `for_user`, `active`)

### Routes
- Devise routes at top level with `path: "api/v1"` — NOT inside namespace
- API resources inside `namespace :api do namespace :v1 do`
- RESTful actions only — no custom routes unless absolutely needed

### Linting
```bash
bin/rubocop          # Run RuboCop
bin/brakeman         # Security scan
bin/bundler-audit    # Gem vulnerabilities
```

---

## 8. Database Best Practices

### Indexes
- Always add indexes on foreign keys
- Composite indexes for common query patterns (e.g., `[user_id, start_date]`)
- Partial unique indexes for conditional uniqueness (e.g., category slug per user)

### Decimals
- Use `decimal(12, 2)` for money — never `float`
- Amount validations: `numericality: { greater_than: 0 }`

### Soft Deletes
- Use `deleted_at` datetime column (not boolean)
- Add `scope :active, -> { where(deleted_at: nil) }` to model
- Add `soft_delete!` method: `update!(deleted_at: Time.current)`

### Migrations
- Always reversible or explicitly `def up` / `def down`
- Drop tables with `if_exists: true`
- Remove FKs before dropping dependent tables

---

## 9. React Frontend Integration

### API Base URL
```javascript
const API_URL = process.env.REACT_APP_API_URL || "http://localhost:3001/api/v1";
```

### Auth Flow
```javascript
// Login
const res = await fetch(`${API_URL}/login`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ user: { email, password } })
});
const token = res.headers.get("authorization"); // "Bearer eyJ..."
localStorage.setItem("token", token);

// Authenticated requests
const res = await fetch(`${API_URL}/expenses`, {
  headers: { "Authorization": localStorage.getItem("token") }
});
```

### Pagination
```javascript
// Request
const res = await fetch(`${API_URL}/expenses?page=2&limit=10`, { headers });
const data = await res.json();

// Use meta for pagination controls
const { current_page, total_pages, next_page, prev_page } = data.meta;
```

### Error Handling
```javascript
const res = await fetch(url, options);
const data = await res.json();

if (!res.ok) {
  // data.errors is always an array
  const messages = data.errors; // ["Error 1", "Error 2"]
  showErrors(messages);
}
```

### CORS
- Backend allows `http://localhost:3001` by default
- Set `FRONTEND_URL` env var in production
- `Authorization` header is exposed for JWT access

---

## 10. Audit Checklist (Run Before Each Phase)

- [ ] All endpoints return consistent JSON format
- [ ] Pagination on all list endpoints (`meta` present)
- [ ] No N+1 queries (check Rails logs)
- [ ] All models have proper validations
- [ ] All controllers scope data to `current_user`
- [ ] All new files have `# frozen_string_literal: true`
- [ ] Strong params on all create/update actions
- [ ] Serializers used for all resource responses
- [ ] `render_error` used for all error responses
- [ ] `head :no_content` for destroy actions
- [ ] No trailing whitespace or style issues
- [ ] `bin/rubocop` passes
- [ ] `bin/brakeman` has no critical warnings
- [ ] Existing tests still pass (`bin/rails test`)
- [ ] New endpoints tested via curl
- [ ] Phase documentation written in `docs/`
