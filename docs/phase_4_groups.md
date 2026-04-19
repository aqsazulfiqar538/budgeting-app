# Phase 4: Groups

## What Was Added

### Migrations
- `db/migrate/20260418100003_create_groups.rb` — `name`, `group_type` (enum), `created_by_id` (FK), `simplify_debts` (boolean), `deleted_at` (soft delete)
- `db/migrate/20260418100004_create_group_memberships.rb` — `group_id` + `user_id` (FKs), UNIQUE constraint

### New Models
- `app/models/group.rb` — belongs_to :creator (User). has_many :group_memberships, :members (through), :expenses. Enum group_type (other/home/trip/couple/apartment). Soft delete via `deleted_at`. Methods: `soft_delete!`, `restore!`, `member?(user)`.
- `app/models/group_membership.rb` — belongs_to :group, :user. Validates uniqueness.

### Model Changes
- `app/models/user.rb` — added `group_memberships`, `groups` (through), `created_groups` associations

### New Controllers
- `app/controllers/api/v1/groups_controller.rb` — full CRUD + restore. Authorization: member for show, creator for update/delete/restore. Creator auto-added as member on create.
- `app/controllers/api/v1/group_members_controller.rb` — add/remove members. Cannot remove the group creator.

### New Serializer
- `app/serializers/group_serializer.rb` — name, group_type, simplify_debts, member_count, members (with name/initials), created_by

### Routes
```ruby
resources :groups do
  member do
    post :restore
  end
  resources :members, controller: "group_members", only: [:create, :destroy]
end
```

## API Endpoints

### List Groups
```
GET /api/v1/groups
Authorization: Bearer <token>
```

### Create Group
```
POST /api/v1/groups
Authorization: Bearer <token>
Content-Type: application/json

{
  "group": { "name": "Office Dinner", "group_type": "trip" },
  "member_ids": [7, 8]
}
```
Creator is auto-added as member. `member_ids` adds additional members.

### Show Group
```
GET /api/v1/groups/:id
```
Only members can view.

### Update Group
```
PATCH /api/v1/groups/:id
```
Only the creator can update.

### Soft Delete / Restore
```
DELETE /api/v1/groups/:id       — soft delete (creator only)
POST   /api/v1/groups/:id/restore — restore (creator only)
```

### Add / Remove Members
```
POST   /api/v1/groups/:group_id/members       — { "user_id": 8 }
DELETE /api/v1/groups/:group_id/members/:id    — remove by user_id
```
Any member can add. Cannot remove the group creator.

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Create group with members | 201 + 2 members | 201 |
| 2 | List groups (user1) | 1 group, paginated | 1 |
| 3 | List groups (user2, member) | 1 group | 1 |
| 4 | Show group | 200 | 200 |
| 5 | Update name (creator) | 200 | 200 |
| 6 | Update (non-creator) | 403 | 403 |
| 7 | Soft delete | 204 | 204 |
| 8 | List after delete | 0 groups | 0 |
| 9 | Restore | 200 | 200 |
| 10 | List after restore | 1 group | 1 |
| 11 | Duplicate member | 422 | 422 |
| 12 | Remove creator | 403 | 403 |

## QA Notes
- N+1 prevented: `includes(:group_memberships, :members, :creator)` on index
- Authorization: member check for show, creator check for update/delete/restore
- Creator auto-added as member on group creation
- Soft delete preserves data — `active` scope filters deleted groups from lists
- Duplicate members prevented by unique index + validation
- Cannot remove the creator from their own group
- Paginated with meta on index
