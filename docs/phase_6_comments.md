# Phase 6: Comments (Slack-like Threads)

## What Was Added

### Migration
- `db/migrate/20260418100008_create_comments.rb` — `expense_id`, `user_id`, `content` (text), `comment_type` (enum: user_comment=0, system_comment=1), `deleted_at` (soft delete). Index on (expense_id, created_at).

### New Model
- `app/models/comment.rb` — belongs_to :expense, :user. Enum comment_type. Scopes: `active`, `chronological`. `soft_delete!` method.

### Model Changes
- `app/models/expense.rb` — added `has_many :comments`
- `app/models/user.rb` — added `has_many :comments`

### Updated Service
- `app/services/expense_creation_service.rb` — now creates a system comment when expense is created:
  - Shared: "Muhammad Arslan created a shared expense 'Lunch' — Rs. 800.0"
  - Individual: "Muhammad Arslan added 'Coffee' — Rs. 350.0"

### New Files
- `app/serializers/comment_serializer.rb` — content, comment_type, created_at, user (name + initials)
- `app/controllers/api/v1/comments_controller.rb` — index (paginated, chronological), create (participants only), destroy (own comments only, soft delete)

### Routes
```ruby
resources :expenses do
  resources :comments, controller: "comments", only: [:index, :create, :destroy]
end
```

## API Endpoints

### List Comments (thread view)
```
GET /api/v1/expenses/:expense_id/comments
Authorization: Bearer <token>
```
Returns system activity + user comments in chronological order (like a Slack thread).

### Add Comment
```
POST /api/v1/expenses/:expense_id/comments
Authorization: Bearer <token>
Content-Type: application/json

{ "content": "Hey, can you settle up?" }
```
Only expense participants (payer or split members) can comment.

### Delete Comment (soft delete)
```
DELETE /api/v1/expenses/:expense_id/comments/:id
Authorization: Bearer <token>
```
Can only delete your own comments.

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Create shared expense | System comment auto-created | 201 |
| 2 | List comments | 1 system comment | Confirmed |
| 3 | User1 adds comment | 201 | 201 |
| 4 | User2 adds comment | 201 | 201 |
| 5 | List all (thread view) | 3 comments chronological, system + user mixed | Confirmed |
| 6 | Delete other's comment | 403 | 403 |
| 7 | Delete own comment | 204 (soft delete) | 204 |
| 8 | List after delete | 2 comments (soft deleted hidden) | Confirmed |
| 9 | Empty content | 422 | 422 |

## QA Notes
- N+1 prevented: `includes(:user)` on comment listing
- Only participants can comment (payer OR split member)
- Can only delete own comments
- Soft delete: sets `deleted_at`, filtered by `active` scope
- System comments auto-created in transaction with expense
- Paginated with meta
- Chronological order (oldest first) — like a chat thread
