# Phase 5: Shared Expenses (Core)

## What Was Added

### Migrations
- `db/migrate/20260418100005_enhance_expenses.rb` — adds `group_id` (nullable FK), `deleted_at` (soft delete)
- `db/migrate/20260418100006_create_expense_participants.rb` — `expense_id`, `user_id`, `paid_share`, `owed_share` (decimal 12,2). UNIQUE(expense_id, user_id).
- `db/migrate/20260418100007_create_repayments.rb` — `expense_id`, `from_user_id`, `to_user_id`, `amount`, `settled`, `settled_at`. Indexes on (from_user_id, settled), (to_user_id, settled).

### New Models
- `app/models/expense_participant.rb` — belongs_to :expense, :user. `net_balance` method (owed - paid).
- `app/models/repayment.rb` — belongs_to :expense, :from_user, :to_user. `settle!` method. Scopes: `unsettled`, `settled`.

### New Service
- `app/services/expense_creation_service.rb` — orchestrates: create expense → create participants → compute repayments. Supports equal split, custom split, and group auto-split. Wrapped in a transaction.

### New Serializers
- `app/serializers/expense_participant_serializer.rb`
- `app/serializers/repayment_serializer.rb`

### Modified Files
- `app/models/expense.rb` — added group, participants, repayments associations. Scopes: `active` (soft delete), `visible_to(user)`. Methods: `shared?`, `soft_delete!`.
- `app/models/user.rb` — added `expense_participants`, `repayments_owed`, `repayments_owing` associations
- `app/serializers/expense_serializer.rb` — added `shared`, `group_id`, `participants` (with paid/owed/net), `repayments` (with from/to/amount/settled)
- `app/controllers/api/v1/expenses_controller.rb` — uses `ExpenseCreationService` for create, `visible_to` for index, `soft_delete!` for destroy

## API Changes

### Create Expense (enhanced)
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json
```

**Individual expense (unchanged):**
```json
{ "expense": { "title": "Coffee", "amount": "350.00", "category_id": 5, "start_date": "2026-04-18" } }
```

**Equal split between specific users:**
```json
{
  "expense": {
    "title": "Lunch", "amount": "1000.00", "category_id": 6, "start_date": "2026-04-18",
    "split_equally": true,
    "participants": [{ "user_id": 6 }, { "user_id": 7 }]
  }
}
```

**Custom split:**
```json
{
  "expense": {
    "title": "Dinner", "amount": "3000.00", "category_id": 6, "start_date": "2026-04-18",
    "participants": [
      { "user_id": 6, "paid_share": "3000.00", "owed_share": "2000.00" },
      { "user_id": 7, "paid_share": "0", "owed_share": "1000.00" }
    ]
  }
}
```

**Group auto-split:**
```json
{
  "expense": {
    "title": "Group Pizza", "amount": "2000.00", "category_id": 6, "start_date": "2026-04-18",
    "group_id": 1, "split_equally": true
  }
}
```

### List Expenses (enhanced)
```
GET /api/v1/expenses
```
Now returns expenses where user is **payer OR participant** (via `visible_to` scope).

### Delete (now soft delete)
```
DELETE /api/v1/expenses/:id → 204 (sets deleted_at, doesn't destroy)
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Individual expense | shared: false, 0 participants | Confirmed |
| 2 | Equal split (2 users) | 2 participants, 1 repayment, correct amounts | Confirmed |
| 3 | Custom split | Custom paid/owed per user, correct repayment | Confirmed |
| 4 | Group auto-split | Auto-splits among group members | Confirmed |
| 5 | User1 list | Sees all (individual + shared) | 7 expenses |
| 6 | User2 list | Sees only shared expenses | 6 shared |
| 7 | Soft delete | 204 | 204 |
| 8 | Hidden after delete | Count decreased | Confirmed |

## QA Notes
- N+1 prevented: `visible_to` uses `left_joins`. Serializer uses `includes(:user)` for participants and `includes(:from_user, :to_user)` for repayments inline.
- Transaction wraps expense + participants + repayments creation — all or nothing.
- `visible_to` scope uses `DISTINCT` to avoid duplicate results from left join.
- Soft delete: `deleted_at` set instead of destroy. `active` scope filters in `filter_by`.
- Repayment math: net_balance = owed_share - paid_share. Positive = owes money. Negative = owed money.
