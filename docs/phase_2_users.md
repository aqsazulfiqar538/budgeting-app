# Phase 2: Users Endpoint

## What Was Added

### Model Changes
- `app/models/user.rb` — added `initials` method (returns uppercase first letter of first + last name)

### New Files
- `app/serializers/user_serializer.rb` — serializes: first_name, last_name, email, phone_number, date_of_birth, full_name, initials
- `app/controllers/api/v1/users_controller.rb` — `me`, `update_me`, `show` actions

### Route Changes
```ruby
get "/users/me", to: "users#me"
patch "/users/me", to: "users#update_me"
resources :users, only: [:show]
```

## API Endpoints

### Get Current User Profile (auth required)
```
GET /api/v1/users/me
Authorization: Bearer <token>
```
**Response (200):**
```json
{
  "data": {
    "id": "6",
    "type": "user",
    "attributes": {
      "first_name": "Arslan",
      "last_name": "Ahmad",
      "email": "arslan@test.com",
      "phone_number": "+923001234567",
      "date_of_birth": "1995-01-01",
      "full_name": "Arslan Ahmad",
      "initials": "AA"
    }
  }
}
```

### Update Profile (auth required)
```
PATCH /api/v1/users/me
Authorization: Bearer <token>
Content-Type: application/json

{ "user": { "first_name": "Muhammad", "last_name": "Arslan" } }
```
**Permitted fields:** first_name, last_name, phone_number, date_of_birth

### View Another User (public)
```
GET /api/v1/users/:id
```

## How to Test

```bash
# Login
curl -s -D - -X POST http://localhost:3001/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"arslan@test.com","password":"password123"}}' | grep authorization
# Copy token

# Get profile
curl http://localhost:3001/api/v1/users/me -H "Authorization: Bearer TOKEN"

# Update profile
curl -X PATCH http://localhost:3001/api/v1/users/me \
  -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" \
  -d '{"user":{"first_name":"Muhammad"}}'

# View another user
curl http://localhost:3001/api/v1/users/6

# Without auth (should 401)
curl http://localhost:3001/api/v1/users/me

# Invalid update (should 422)
curl -X PATCH http://localhost:3001/api/v1/users/me \
  -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" \
  -d '{"user":{"first_name":""}}'
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | GET /users/me | 200 + initials | 200 |
| 2 | PATCH /users/me | 200 + updated | 200 |
| 3 | Verify update | name/initials changed | Confirmed |
| 4 | GET /users/:id | 200 | 200 |
| 5 | GET /users/me without auth | 401 | 401 |
| 6 | PATCH with blank name | 422 + errors | 422 |
