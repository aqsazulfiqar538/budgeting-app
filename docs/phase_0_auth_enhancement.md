# Phase 0: Auth Enhancement (Forgot Password + Confirmable Email)

## What Was Added

### Migration
- `db/migrate/20260417100001_add_confirmable_to_users.rb` — adds `confirmation_token`, `confirmed_at`, `confirmation_sent_at`, `unconfirmed_email` to users table. Existing users are auto-confirmed.

### Model Changes
- `app/models/user.rb` — added `:confirmable` to devise modules

### New Controllers
- `app/controllers/api/v1/passwords_controller.rb` — handles forgot password (send reset email) and reset password (with token)
- `app/controllers/api/v1/confirmations_controller.rb` — handles account confirmation (via token) and resend confirmation email

### Modified Controllers
- `app/controllers/api/v1/registrations_controller.rb` — updated signup response to show confirmation required message

### Config Changes
- `config/environments/development.rb` — configured `letter_opener` for email delivery in dev (emails open in browser)
- `config/initializers/devise.rb` — updated `mailer_sender` to `noreply@budgetingapp.com`
- `config/routes.rb` — added `passwords` and `confirmations` controllers to devise routes

## API Endpoints

### Confirmation
```
POST   /api/v1/confirmation                     — resend confirmation email
GET    /api/v1/confirmation?confirmation_token=X — confirm account
```

### Password Reset
```
POST   /api/v1/password                          — send reset email (params: { user: { email } })
PATCH  /api/v1/password                          — reset password (params: { user: { reset_password_token, password, password_confirmation } })
```

### Updated Signup Response
```
POST   /api/v1/signup                            — now returns "Please check your email to confirm your account"
```

## How to Test

### Postman / curl

**1. Sign up (new user gets confirmation email)**
```bash
curl -X POST http://localhost:3001/api/v1/signup \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123","password_confirmation":"password123","first_name":"Test","last_name":"User","phone_number":"+920001111","date_of_birth":"2000-01-01"}}'
# Response: 201 — "Please check your email to confirm your account."
```

**2. Login before confirming (should fail)**
```bash
curl -X POST http://localhost:3001/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'
# Response: 401 — "You have to confirm your email address before continuing."
```

**3. Get confirmation token (dev only — via rails console)**
```bash
bin/rails runner "puts User.last.confirmation_token"
```

**4. Confirm account**
```bash
curl "http://localhost:3001/api/v1/confirmation?confirmation_token=YOUR_TOKEN"
# Response: 200 — "Account confirmed successfully. You can now log in."
```

**5. Login after confirmation**
```bash
curl -X POST http://localhost:3001/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'
# Response: 200 — JWT token in Authorization header
```

**6. Forgot password**
```bash
curl -X POST http://localhost:3001/api/v1/password \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com"}}'
# Response: 200 — "Reset password instructions sent to your email."
```

**7. Get reset token (dev only — via rails console)**
```bash
bin/rails runner "raw, enc = Devise.token_generator.generate(User, :reset_password_token); User.last.update_columns(reset_password_token: enc, reset_password_sent_at: Time.current); puts raw"
```

**8. Reset password**
```bash
curl -X PATCH http://localhost:3001/api/v1/password \
  -H "Content-Type: application/json" \
  -d '{"user":{"reset_password_token":"YOUR_TOKEN","password":"newpassword","password_confirmation":"newpassword"}}'
# Response: 200 — "Password has been reset successfully."
```

**9. Resend confirmation (already confirmed user)**
```bash
curl -X POST http://localhost:3001/api/v1/confirmation \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com"}}'
# Response: 422 — "Email was already confirmed, please try signing in"
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Sign up | 201 + confirmation message | 201 |
| 2 | Login before confirm | 401 | 401 |
| 3 | Confirm with token | 200 | 200 |
| 4 | Login after confirm | 200 + JWT | 200 |
| 5 | Forgot password | 200 | 200 |
| 6 | Reset password | 200 | 200 |
| 7 | Login with new password | 200 | 200 |
| 8 | Resend for confirmed user | 422 | 422 |

## Notes
- In development, emails are handled by `letter_opener` — they save as HTML files in `tmp/letter_opener/`
- For production, switch `delivery_method` to `:smtp` with Mailtrap or SendGrid credentials
- Existing users were auto-confirmed in the migration so they aren't locked out
- `reconfirmable` is enabled — changing email requires re-confirmation
