# Phase 3: Friendships

## What Was Added

### Migration
- `db/migrate/20260418100002_create_friendships.rb` — `user_id` (FK, always smaller ID), `friend_id` (FK, always larger ID), `requested_by_id` (FK), `status` (enum). CHECK constraint ensures canonical ordering. UNIQUE on (user_id, friend_id).

### New Model
- `app/models/friendship.rb` — Self-join through table. Canonical ordering (smaller ID always in `user_id`). Enum status: pending/accepted/rejected. Scopes: `involving(user)`, `accepted`, `pending_for(user)`. `other_user(current)` method returns the friend.

### Model Changes
- `app/models/user.rb` — added `friendships_as_user`, `friendships_as_friend` associations + `friends` method (returns accepted friend User records)

### New Controllers
- `app/controllers/api/v1/friends_controller.rb` — index (list accepted), show, create (send request), destroy (remove)
- `app/controllers/api/v1/friend_requests_controller.rb` — index (pending incoming), accept, reject

### New Serializer
- `app/serializers/friendship_serializer.rb` — returns friend info (name, initials), status, requested_by_me flag

### Routes
```ruby
resources :friends, only: [:index, :show, :create, :destroy] do
  collection do
    get :requests, to: "friend_requests#index"
  end
  member do
    patch :accept, to: "friend_requests#accept"
    patch :reject, to: "friend_requests#reject"
  end
end
```

## API Endpoints

### List Friends (accepted)
```
GET /api/v1/friends
Authorization: Bearer <token>
```

### Send Friend Request
```
POST /api/v1/friends
Authorization: Bearer <token>
Content-Type: application/json

{ "friend_id": 7 }
```

### List Pending Requests (incoming)
```
GET /api/v1/friends/requests
Authorization: Bearer <token>
```

### Accept Request
```
PATCH /api/v1/friends/:id/accept
Authorization: Bearer <token>
```

### Reject Request
```
PATCH /api/v1/friends/:id/reject
Authorization: Bearer <token>
```

### Remove Friendship
```
DELETE /api/v1/friends/:id
Authorization: Bearer <token>
```

## How to Test

```bash
# Create 2 users, login as both, get tokens

# User1 sends request to User2
curl -X POST http://localhost:3001/api/v1/friends \
  -H "Authorization: Bearer TOKEN1" -H "Content-Type: application/json" \
  -d '{"friend_id": USER2_ID}'

# User2 sees pending request
curl http://localhost:3001/api/v1/friends/requests -H "Authorization: Bearer TOKEN2"

# User2 accepts
curl -X PATCH http://localhost:3001/api/v1/friends/FRIENDSHIP_ID/accept \
  -H "Authorization: Bearer TOKEN2"

# Both see each other in friends list
curl http://localhost:3001/api/v1/friends -H "Authorization: Bearer TOKEN1"
curl http://localhost:3001/api/v1/friends -H "Authorization: Bearer TOKEN2"
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Send request | 201 + pending | 201 |
| 2 | Friends list (pending) | 0 friends | 0 |
| 3 | Pending requests (recipient) | 1 request, requested_by_me: false | Confirmed |
| 4 | Accept request | 200 + accepted | 200 |
| 5 | Friends list (user1) | 1 friend (Ahmad Khan) | Confirmed |
| 6 | Friends list (user2) | 1 friend (Muhammad Arslan) | Confirmed |
| 7 | Duplicate request | 422 | 422 |
| 8 | Self-friend | 422 | 422 |
| 9 | Remove friendship | 204 | 204 |
| 10 | Friends list (after removal) | 0 | 0 |

## QA Notes
- N+1 prevented: `includes(:user, :friend)` on all list queries
- Canonical ordering: user_id always < friend_id, enforced by DB CHECK constraint + model validation
- Authorization: only recipient can accept/reject (not the requester)
- Pagination: both list endpoints use pagy with meta
- Self-friendship prevented by validation
- Duplicate friendship prevented by unique index + validation
