# Phase 8: Notifications

## What Was Added

### Migration
- `db/migrate/20260418100009_create_notifications.rb` — `user_id` (recipient), `created_by_id` (actor), `notification_type` (enum), `content` (text), `source_type`/`source_id` (polymorphic), `read_at`. Indexes on (user_id, read_at, created_at) and (source_type, source_id).

### New Model
- `app/models/notification.rb` — polymorphic source, enum types (expense_added, expense_updated, expense_deleted, comment_added, added_to_group, removed_from_group, group_deleted, friend_added, friend_removed, debt_settled). Scopes: `unread`, `recent`.

### New Service
- `app/services/notification_service.rb` — class methods for each trigger:
  - `expense_created` → notifies participants (not the creator)
  - `expense_updated` / `expense_deleted` → same
  - `comment_added` → notifies participants (not the commenter)
  - `added_to_group` / `removed_from_group` → notifies the affected user
  - `friend_request_sent` → notifies recipient
  - `friend_request_accepted` → notifies requester
  - `debt_settled` → notifies the other party

### New Files
- `app/serializers/notification_serializer.rb` — type, content, read, created_by (name + initials), source (type + id), created_at
- `app/controllers/api/v1/notifications_controller.rb` — index (paginated + unread_count in meta), mark_read

### Wired Into
- `ExpenseCreationService` → `expense_created`
- `CommentsController#create` → `comment_added`
- `FriendsController#create` → `friend_request_sent`
- `FriendRequestsController#accept` → `friend_request_accepted`
- `GroupMembersController#create` → `added_to_group`
- `GroupMembersController#destroy` → `removed_from_group`

### Model Changes
- `app/models/user.rb` — added `has_many :notifications`

### Routes
```ruby
resources :notifications, only: [:index] do
  collection do
    patch :mark_read
  end
end
```

## API Endpoints

### List Notifications
```
GET /api/v1/notifications
Authorization: Bearer <token>
```
Returns paginated notifications (newest first) with `unread_count` in meta.

### Mark All as Read
```
PATCH /api/v1/notifications/mark_read
Authorization: Bearer <token>
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Create shared expense | Notification sent to participant | 201 |
| 2 | User2 notifications | 1 expense_added notification, unread: 1 | Confirmed |
| 3 | Add comment | Notification sent | 201 |
| 4 | User2 notifications | 2 notifications (expense + comment), unread: 2 | Confirmed |
| 5 | Mark all read | 200 | 200 |
| 6 | After mark_read | unread: 0, first item read: true | Confirmed |
| 7 | Actor sees no notifications | count: 0 (actor is excluded) | Confirmed |
| 8 | No auth | 401 | 401 |

## QA Notes
- Actor is excluded from notifications — you don't get notified of your own actions
- Notifications sent outside the transaction (after commit) to avoid slowing down the main action
- `unread_count` included in meta on every notification list request — React can use this for badge count
- `includes(:created_by)` prevents N+1 on listing
- Paginated with meta
- Polymorphic `source` links back to the triggering record (Expense, Group, Friendship)
