# Phase 7: Ledger + Dashboard

## What Was Added

### New Service
- `app/services/ledger_service.rb` — computes balances from unsettled repayments.
  - `summary` — 2 SQL queries (GROUP BY from_user_id + GROUP BY to_user_id) + 1 user lookup. Returns `i_owe` list + `owed_to_me` list with totals.
  - `detail(friend_id)` — breakdown of all unsettled repayments with a specific friend, with expense titles and net balance.

### New Controller
- `app/controllers/api/v1/ledger_controller.rb` — `index` (summary), `show` (detail with friend)

### Modified Controller
- `app/controllers/api/v1/dashboard_controller.rb` — enhanced with:
  - `recent_ledger_activity` — top 5 recent repayments (includes expense/user details)
  - `ledger_summary` — full i_owe/owed_to_me from LedgerService
  - Uses `active` scope to exclude soft-deleted expenses from totals

### Routes
```ruby
resources :ledger, only: [:index, :show], controller: "ledger"
```

## API Endpoints

### Ledger Summary (2 cards: "I owe" + "Owed to me")
```
GET /api/v1/ledger
Authorization: Bearer <token>
```
**Response:**
```json
{
  "i_owe": [
    { "user_id": 7, "full_name": "Ahmad Khan", "initials": "AK", "amount": "1500.0" }
  ],
  "owed_to_me": [
    { "user_id": 8, "full_name": "Sara Ali", "initials": "SA", "amount": "500.0" }
  ],
  "total_i_owe": "1500.0",
  "total_owed_to_me": "500.0"
}
```

### Ledger Detail (breakdown with specific friend)
```
GET /api/v1/ledger/:friend_id
Authorization: Bearer <token>
```
**Response:**
```json
{
  "friend": { "id": 7, "full_name": "Ahmad Khan", "initials": "AK" },
  "they_owe_me": [
    { "id": 1, "amount": "500.0", "expense_title": "Shared Lunch", "expense_id": 12, "created_at": "..." }
  ],
  "i_owe_them": [],
  "total_they_owe_me": "500.0",
  "total_i_owe_them": "0.0",
  "net": "500.0"
}
```

### Dashboard (enhanced)
```
GET /api/v1/dashboard
Authorization: Bearer <token>
```
**Response:**
```json
{
  "total_expenses": "11150.0",
  "current_month_total": "11150.0",
  "category_totals": { "Groceries": "350.0", "Dining Out": "10800.0" },
  "recent_expenses": { "data": [...], "included": [...] },
  "recent_ledger_activity": [
    {
      "id": 1,
      "expense_title": "Shared Lunch",
      "from": { "id": 7, "full_name": "Ahmad Khan", "initials": "AK" },
      "to": { "id": 6, "full_name": "Muhammad Arslan", "initials": "MA" },
      "amount": "500.0",
      "settled": false,
      "created_at": "..."
    }
  ],
  "ledger_summary": {
    "i_owe": [...],
    "owed_to_me": [...],
    "total_i_owe": "0",
    "total_owed_to_me": "5400.0"
  }
}
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Ledger User1 | Ahmad owes Rs. 5400 | Confirmed |
| 2 | Ledger User2 | Owes Arslan Rs. 5400 | Confirmed |
| 3 | Detail (User1 ↔ User2) | 7 repayments, net +5400 | Confirmed |
| 4 | Dashboard | totals + 5 recent + 5 ledger + summary | All present |
| 5 | Nonexistent friend | 404 | 404 |
| 6 | No auth | 401 | 401 |

## QA Notes
- N+1 prevented: `index_by(&:id)` for user lookup in summary (1 query), `includes(:expense)` in detail
- Dashboard uses `active` scope — soft-deleted expenses excluded from totals
- Ledger computed from unsettled repayments — settling a repayment automatically updates the ledger
- `recent_ledger_activity` uses `includes(:expense, :from_user, :to_user)` to prevent N+1
- No extra tables needed — ledger is computed from existing `repayments` table
