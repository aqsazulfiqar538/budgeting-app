# Phase 9: Settlement

## What Was Added

### New Controller
- `app/controllers/api/v1/repayments_controller.rb` — `settle` action. Wrapped in transaction:
  1. Marks repayment as settled (`settled: true`, `settled_at`)
  2. Creates a settlement expense record (visible in expense history, shows money flow)
  3. Creates a system comment on the original expense ("Ahmad Khan settled Rs. 1000.0")
  4. Sends notification to the other party (outside transaction)

### Seeds Update
- `db/seeds.rb` — added "Settlement" system category (slug: "settlement", icon: "handshake")

### Routes
```ruby
resources :repayments, only: [] do
  member do
    patch :settle
  end
end
```

## API Endpoint

### Settle a Repayment
```
PATCH /api/v1/repayments/:id/settle
Authorization: Bearer <token>
```

Either the person who owes (from_user) or the person who is owed (to_user) can settle.

**Response (200):**
```json
{
  "message": "Settled successfully",
  "repayment": {
    "id": 9,
    "amount": "1000.0",
    "from": { "id": 7, "full_name": "Ahmad Khan" },
    "to": { "id": 6, "full_name": "Muhammad Arslan" },
    "settled": true,
    "settled_at": "2026-04-18T15:57:54.136Z"
  }
}
```

### What Happens on Settle

1. **Repayment** marked as settled
2. **Settlement expense** created — title: "Settlement: Ahmad Khan → Muhammad Arslan", amount: Rs. 1000, category: Settlement. Visible in expense list to show money flow.
3. **System comment** on original expense — "Ahmad Khan settled Rs. 1000.0"
4. **Notification** to the other party — "Ahmad Khan settled Rs. 1000.0 for 'Settlement Test Meal'"
5. **Ledger** automatically updated — settled repayments excluded from unsettled totals

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | Create shared expense | 201 | 201 |
| 2 | Get repayment ID | Present | ID: 9 |
| 3 | Ledger before | they_owe_me: 6700 | 6700 |
| 4 | Settle repayment | 200 + settled: true | 200 |
| 5 | Ledger after | they_owe_me: 5700 (reduced by 1000) | 5700 |
| 6 | System comment created | "Ahmad Khan settled Rs. 1000.0" | Confirmed |
| 7 | Notification sent | debt_settled notification | Confirmed |
| 8 | Settlement expense visible | "Settlement: Ahmad Khan → Muhammad Arslan" in list | Confirmed |
| 9 | Double settle | 422 "Already settled" | 422 |
| 10 | Nonexistent repayment | 404 | 404 |

## QA Notes
- Transaction wraps settle + expense creation + comment — all or nothing
- Notification sent outside transaction to avoid slowing down the main action
- Either party (ower or owed) can settle — both have visibility
- Double settle prevented — returns 422
- Settlement expense uses the system "Settlement" category (seeded)
- Settlement expense linked to same group as the original expense (if any)
- Ledger auto-updates — `unsettled` scope excludes settled repayments
