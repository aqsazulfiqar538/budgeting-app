# API Testing Guide

> Complete guide to test every feature of the Budgeting App API. Use Postman, curl, or any HTTP client.

**Base URL:** `http://localhost:3001`

---

## Table of Contents

1. [Auth: Signup, Confirm, Login, Logout, Forgot Password](#1-auth)
2. [User Profile](#2-user-profile)
3. [Categories](#3-categories)
4. [Individual Expenses (CRUD)](#4-individual-expenses)
5. [Friendships](#5-friendships)
6. [Groups](#6-groups)
7. [Shared Expenses (Splits)](#7-shared-expenses)
8. [Comments (Slack-like Threads)](#8-comments)
9. [Ledger (Who Owes Whom)](#9-ledger)
10. [Dashboard](#10-dashboard)
11. [Notifications](#11-notifications)
12. [Settlement](#12-settlement)
13. [Security Tests](#13-security)
14. [Error Handling](#14-error-handling)

---

## Setup

Start the server:
```bash
bin/dev
```

All authenticated requests need this header:
```
Authorization: Bearer <your_jwt_token>
```

The JWT token comes from the **response header** (not body) when you login:
```
authorization: Bearer eyJhbGciOiJIUzI1...
```

---

## 1. Auth

### 1.1 Sign Up
```
POST /api/v1/signup
Content-Type: application/json

{
  "user": {
    "email": "arslan@test.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "Arslan",
    "last_name": "Ahmad",
    "phone_number": "+923001234567",
    "date_of_birth": "1995-01-01"
  }
}
```
**Expected:** 201 — "Please check your email to confirm your account."

### 1.2 Login Before Confirming (should fail)
```
POST /api/v1/login
Content-Type: application/json

{
  "user": {
    "email": "arslan@test.com",
    "password": "password123"
  }
}
```
**Expected:** 401 — "You have to confirm your email address before continuing."

### 1.3 Get Confirmation Token (dev only)
```bash
bin/rails runner "puts User.find_by(email: 'arslan@test.com').confirmation_token"
```

### 1.4 Confirm Account
```
GET /api/v1/confirmation?confirmation_token=YOUR_TOKEN
```
**Expected:** 200 — "Account confirmed successfully. You can now log in."

### 1.5 Login
```
POST /api/v1/login
Content-Type: application/json

{
  "user": {
    "email": "arslan@test.com",
    "password": "password123"
  }
}
```
**Expected:** 200 — Check **response headers** for `authorization: Bearer eyJ...`

### 1.6 Forgot Password
```
POST /api/v1/password
Content-Type: application/json

{
  "user": {
    "email": "arslan@test.com"
  }
}
```
**Expected:** 200 — "Reset password instructions sent to your email."

### 1.7 Reset Password (get token via rails console)
```bash
bin/rails runner "raw, enc = Devise.token_generator.generate(User, :reset_password_token); User.find_by(email: 'arslan@test.com').update_columns(reset_password_token: enc, reset_password_sent_at: Time.current); puts raw"
```

```
PATCH /api/v1/password
Content-Type: application/json

{
  "user": {
    "reset_password_token": "YOUR_TOKEN",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
  }
}
```
**Expected:** 200 — "Password has been reset successfully."

### 1.8 Logout
```
DELETE /api/v1/logout
Authorization: Bearer <token>
```
**Expected:** 200 — "Logged out successfully."

### 1.9 Resend Confirmation (already confirmed)
```
POST /api/v1/confirmation
Content-Type: application/json

{
  "user": {
    "email": "arslan@test.com"
  }
}
```
**Expected:** 422 — "Email was already confirmed"

---

## 2. User Profile

### 2.1 Get My Profile
```
GET /api/v1/users/me
Authorization: Bearer <token>
```
**Expected:** 200 — Returns full profile with `initials` (e.g. "AA")

### 2.2 Update My Profile
```
PATCH /api/v1/users/me
Authorization: Bearer <token>
Content-Type: application/json

{
  "user": {
    "first_name": "Muhammad",
    "last_name": "Arslan"
  }
}
```
**Expected:** 200 — Updated profile, initials now "MA"

### 2.3 View Another User (public info only)
```
GET /api/v1/users/7
Authorization: Bearer <token>
```
**Expected:** 200 — Returns only first_name, last_name, full_name, initials (no email/phone)

### 2.4 Update with Invalid Data
```
PATCH /api/v1/users/me
Authorization: Bearer <token>
Content-Type: application/json

{
  "user": {
    "first_name": ""
  }
}
```
**Expected:** 422 — `{ "errors": ["First name can't be blank"] }`

---

## 3. Categories

### 3.1 List All Categories (public, no auth needed)
```
GET /api/v1/categories
```
**Expected:** 200 — Tree structure with parent categories + nested subcategories

### 3.2 List Categories with Auth (includes custom)
```
GET /api/v1/categories
Authorization: Bearer <token>
```
**Expected:** 200 — System categories + user's custom categories

### 3.3 Create Custom Category
```
POST /api/v1/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "category": {
    "name": "Office Lunch",
    "icon": "briefcase"
  }
}
```
**Expected:** 201 — `"custom": true`

### 3.4 Create Custom Subcategory (under Food, id=1)
```
POST /api/v1/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "category": {
    "name": "Street Food",
    "icon": "food-stand",
    "parent_id": 1
  }
}
```
**Expected:** 201 — `"parent_id": 1`

---

## 4. Individual Expenses

### 4.1 Create Individual Expense
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Grocery Shopping",
    "amount": "2500.00",
    "category_id": 5,
    "start_date": "2026-04-18",
    "notes": "Weekly groceries"
  }
}
```
**Expected:** 201 — `"shared": false`, empty participants

### 4.2 List Expenses (paginated)
```
GET /api/v1/expenses
Authorization: Bearer <token>
```
**Expected:** 200 — `data` array + `meta` with `current_page`, `total_pages`, `total_count`, `per_page`

### 4.3 List with Filters
```
GET /api/v1/expenses?category_id=5
GET /api/v1/expenses?start_date=2026-04-01&end_date=2026-04-30
GET /api/v1/expenses?page=2
GET /api/v1/expenses?category_id=5&start_date=2026-04-01&end_date=2026-04-30&page=1
```

### 4.4 Show Single Expense
```
GET /api/v1/expenses/:id
Authorization: Bearer <token>
```
**Expected:** 200 — Full expense with participants, repayments, category

### 4.5 Update Expense
```
PATCH /api/v1/expenses/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Updated Groceries",
    "amount": "3000.00"
  }
}
```
**Expected:** 200 — Only the payer can update

### 4.6 Delete Expense (Soft Delete)
```
DELETE /api/v1/expenses/:id
Authorization: Bearer <token>
```
**Expected:** 204 No Content — Expense is soft-deleted (hidden from lists, not destroyed)

---

## 5. Friendships

> **Setup:** Create a second user first (see Section 1.1 with different email)

### 5.1 Send Friend Request
```
POST /api/v1/friends
Authorization: Bearer <token_user1>
Content-Type: application/json

{
  "friend_id": 7
}
```
**Expected:** 201 — `"status": "pending"`, `"requested_by_me": true`

### 5.2 List Pending Requests (as recipient)
```
GET /api/v1/friends/requests
Authorization: Bearer <token_user2>
```
**Expected:** 200 — Shows incoming request with `"requested_by_me": false`

### 5.3 Accept Friend Request
```
PATCH /api/v1/friends/:friendship_id/accept
Authorization: Bearer <token_user2>
```
**Expected:** 200 — `"status": "accepted"`

### 5.4 Reject Friend Request
```
PATCH /api/v1/friends/:friendship_id/reject
Authorization: Bearer <token_user2>
```
**Expected:** 204

### 5.5 List Friends (accepted only)
```
GET /api/v1/friends
Authorization: Bearer <token>
```
**Expected:** 200 — Paginated list of accepted friends with name + initials

### 5.6 Show Friend Detail
```
GET /api/v1/friends/:friendship_id
Authorization: Bearer <token>
```
**Expected:** 200

### 5.7 Remove Friendship
```
DELETE /api/v1/friends/:friendship_id
Authorization: Bearer <token>
```
**Expected:** 204

### 5.8 Self-Friend (should fail)
```
POST /api/v1/friends
Authorization: Bearer <token>
Content-Type: application/json

{
  "friend_id": YOUR_OWN_ID
}
```
**Expected:** 422

### 5.9 Duplicate Request (should fail)
Send the same friend request twice.
**Expected:** 422 — "friendship already exists"

---

## 6. Groups

> **Prerequisite:** Have at least one accepted friendship (Section 5)

### 6.1 Create Group with Members
```
POST /api/v1/groups
Authorization: Bearer <token>
Content-Type: application/json

{
  "group": {
    "name": "Office Dinner",
    "group_type": "trip"
  },
  "member_ids": [7]
}
```
**Expected:** 201 — Creator auto-added as member. Only friends can be added.

**group_type options:** `other`, `home`, `trip`, `couple`, `apartment`

### 6.2 List My Groups
```
GET /api/v1/groups
Authorization: Bearer <token>
```
**Expected:** 200 — Paginated with member count

### 6.3 Show Group Detail
```
GET /api/v1/groups/:id
Authorization: Bearer <token>
```
**Expected:** 200 — Only members can view

### 6.4 Update Group (creator only)
```
PATCH /api/v1/groups/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "group": {
    "name": "Friday Lunch"
  }
}
```
**Expected:** 200 (creator) or 403 (non-creator)

### 6.5 Add Member (must be a friend)
```
POST /api/v1/groups/:group_id/members
Authorization: Bearer <token>
Content-Type: application/json

{
  "user_id": 7
}
```
**Expected:** 201 (friend) or 403 (non-friend: "Can only add friends to groups")

### 6.6 Remove Member
```
DELETE /api/v1/groups/:group_id/members/:user_id
Authorization: Bearer <token>
```
**Expected:** 204 — Cannot remove the group creator (403)

### 6.7 Soft Delete Group (creator only)
```
DELETE /api/v1/groups/:id
Authorization: Bearer <token>
```
**Expected:** 204

### 6.8 Restore Group (creator only)
```
POST /api/v1/groups/:id/restore
Authorization: Bearer <token>
```
**Expected:** 200

---

## 7. Shared Expenses

> **Prerequisite:** Have accepted friendships (Section 5) and optionally a group (Section 6)

### 7.1 Equal Split Between Friends
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Shared Lunch",
    "amount": "1000.00",
    "category_id": 6,
    "start_date": "2026-04-18",
    "split_equally": true,
    "participants": [
      { "user_id": 6 },
      { "user_id": 7 }
    ]
  }
}
```
**Expected:** 201 — `"shared": true`, 2 participants with equal owed_share (500 each), 1 repayment (Ahmad → Arslan Rs. 500)

### 7.2 Custom Split
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Dinner - Custom Split",
    "amount": "3000.00",
    "category_id": 6,
    "start_date": "2026-04-18",
    "participants": [
      { "user_id": 6, "paid_share": "3000.00", "owed_share": "2000.00" },
      { "user_id": 7, "paid_share": "0.00", "owed_share": "1000.00" }
    ]
  }
}
```
**Expected:** 201 — Custom paid/owed per person. Repayment: Ahmad → Arslan Rs. 1000

### 7.3 Group Auto-Split
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Group Pizza",
    "amount": "2000.00",
    "category_id": 6,
    "start_date": "2026-04-18",
    "group_id": 1,
    "split_equally": true
  }
}
```
**Expected:** 201 — Auto-splits among all group members

### 7.4 Bad Custom Split (totals don't match)
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Bad Split",
    "amount": "1000.00",
    "category_id": 6,
    "start_date": "2026-04-18",
    "participants": [
      { "user_id": 6, "paid_share": "1000", "owed_share": "600" },
      { "user_id": 7, "paid_share": "0", "owed_share": "200" }
    ]
  }
}
```
**Expected:** 422 — "Total owed shares (800.0) must equal expense amount (1000.0)"

### 7.5 Expense with Non-Friend (should fail)
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "Scam",
    "amount": "5000.00",
    "category_id": 5,
    "start_date": "2026-04-18",
    "participants": [
      { "user_id": 6, "paid_share": "5000", "owed_share": "0" },
      { "user_id": 999, "paid_share": "0", "owed_share": "5000" }
    ]
  }
}
```
**Expected:** 422 — "Users 999 are not your friends"

### 7.6 Non-Member Creates Group Expense (should fail)
Login as a user who is NOT a member of the group, then:
```
POST /api/v1/expenses
Authorization: Bearer <stranger_token>
Content-Type: application/json

{
  "expense": {
    "title": "Hijack",
    "amount": "5000.00",
    "category_id": 5,
    "start_date": "2026-04-18",
    "group_id": 1,
    "split_equally": true
  }
}
```
**Expected:** 422 — "You are not a member of this group"

### 7.7 List Expenses (shows both payer and participant expenses)
```
GET /api/v1/expenses
Authorization: Bearer <token_user2>
```
**Expected:** 200 — User2 sees expenses where they are a participant (not just payer)

### 7.8 Non-Payer Cannot Update
```
PATCH /api/v1/expenses/:id
Authorization: Bearer <token_user2>
Content-Type: application/json

{
  "expense": { "title": "Hacked" }
}
```
**Expected:** 403 — "Only the payer can perform this action"

---

## 8. Comments

> **Prerequisite:** Have a shared expense (Section 7)

### 8.1 List Comments (thread view)
```
GET /api/v1/expenses/:expense_id/comments
Authorization: Bearer <token>
```
**Expected:** 200 — System comment auto-created when expense was created + any user comments. Chronological order (oldest first).

### 8.2 Add Comment
```
POST /api/v1/expenses/:expense_id/comments
Authorization: Bearer <token>
Content-Type: application/json

{
  "content": "Hey, can you settle up?"
}
```
**Expected:** 201 — `"comment_type": "user_comment"`

### 8.3 User2 Adds Comment
```
POST /api/v1/expenses/:expense_id/comments
Authorization: Bearer <token_user2>
Content-Type: application/json

{
  "content": "Sure, will send tomorrow!"
}
```
**Expected:** 201

### 8.4 Delete Own Comment
```
DELETE /api/v1/expenses/:expense_id/comments/:comment_id
Authorization: Bearer <token_user2>
```
**Expected:** 204 (soft delete — hidden from list but not destroyed)

### 8.5 Delete Someone Else's Comment (should fail)
```
DELETE /api/v1/expenses/:expense_id/comments/:other_users_comment_id
Authorization: Bearer <token_user1>
```
**Expected:** 403 — "Can only delete your own comments"

### 8.6 Empty Comment (should fail)
```
POST /api/v1/expenses/:expense_id/comments
Authorization: Bearer <token>
Content-Type: application/json

{
  "content": ""
}
```
**Expected:** 422

---

## 9. Ledger

> **Prerequisite:** Have shared expenses with unsettled repayments (Section 7)

### 9.1 Ledger Summary (2 cards: I owe + Owed to me)
```
GET /api/v1/ledger
Authorization: Bearer <token>
```
**Expected:** 200
```json
{
  "i_owe": [
    { "id": 7, "first_name": "Ahmad", "full_name": "Ahmad Khan", "initials": "AK", "amount": "1500.0" }
  ],
  "owed_to_me": [
    { "id": 8, "first_name": "Sara", "full_name": "Sara Ali", "initials": "SA", "amount": "500.0" }
  ],
  "total_i_owe": "1500.0",
  "total_owed_to_me": "500.0"
}
```

### 9.2 Ledger Detail (breakdown with specific friend)
```
GET /api/v1/ledger/:friend_id
Authorization: Bearer <token>
```
**Expected:** 200 — Lists each unsettled repayment with expense title + amount + net balance

### 9.3 Ledger Detail with Non-Friend (should fail)
```
GET /api/v1/ledger/999
Authorization: Bearer <token>
```
**Expected:** 403 — "Not friends with this user" (or 404 if user doesn't exist)

---

## 10. Dashboard

### 10.1 Full Dashboard
```
GET /api/v1/dashboard
Authorization: Bearer <token>
```
**Expected:** 200
```json
{
  "total_expenses": "15000.0",
  "current_month_total": "8000.0",
  "category_totals": { "Groceries": "2500.0", "Dining Out": "5500.0" },
  "recent_expenses": { "data": [...], "included": [...] },
  "recent_ledger_activity": [
    {
      "id": 1,
      "expense_title": "Shared Lunch",
      "from": { "id": 7, "full_name": "Ahmad Khan", ... },
      "to": { "id": 6, "full_name": "Muhammad Arslan", ... },
      "amount": "500.0",
      "settled": false
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

---

## 11. Notifications

> Notifications are auto-created when: expense created/updated/deleted, comment added, added/removed from group, friend request sent/accepted, debt settled.

### 11.1 List Notifications
```
GET /api/v1/notifications
Authorization: Bearer <token>
```
**Expected:** 200 — Paginated. `meta.unread_count` shows badge count for the frontend.

### 11.2 Mark All as Read
```
PATCH /api/v1/notifications/mark_read
Authorization: Bearer <token>
```
**Expected:** 200 — All notifications marked as read. `unread_count` becomes 0.

### 11.3 Verify Actor Excluded
After creating an expense, check the creator's notifications — they should NOT see their own action.

---

## 12. Settlement

> **Prerequisite:** Have a shared expense with an unsettled repayment

### 12.1 Get Repayment ID
```
GET /api/v1/expenses/:expense_id
Authorization: Bearer <token>
```
Look at `attributes.repayments[0].id`

### 12.2 Settle a Repayment
```
PATCH /api/v1/repayments/:repayment_id/settle
Authorization: Bearer <token>
```
**Expected:** 200
```json
{
  "message": "Settled successfully",
  "repayment": {
    "id": 9,
    "amount": "500.0",
    "from": { "id": 7, "full_name": "Ahmad Khan" },
    "to": { "id": 6, "full_name": "Muhammad Arslan" },
    "settled": true,
    "settled_at": "2026-04-18T..."
  }
}
```

**Side effects to verify:**
- `GET /api/v1/ledger` — amount reduced
- `GET /api/v1/expenses/:expense_id/comments` — system comment: "Ahmad Khan settled Rs. 500.0"
- `GET /api/v1/notifications` (as other user) — "Ahmad Khan settled Rs. 500.0 for 'Shared Lunch'"
- `GET /api/v1/expenses` — new "Settlement: Ahmad Khan → Muhammad Arslan" expense visible

### 12.3 Double Settle (should fail)
```
PATCH /api/v1/repayments/:same_id/settle
Authorization: Bearer <token>
```
**Expected:** 422 — "Already settled"

---

## 13. Security Tests

### 13.1 No Token
```
GET /api/v1/expenses
```
**Expected:** 401

### 13.2 Invalid Token
```
GET /api/v1/expenses
Authorization: Bearer invalid_token_here
```
**Expected:** 401

### 13.3 Access Other User's Expense (not participant)
```
GET /api/v1/expenses/:other_users_expense_id
Authorization: Bearer <your_token>
```
**Expected:** 404 (not 403 — don't reveal existence)

### 13.4 Rate Limiting (6 rapid bad logins)
```bash
for i in $(seq 1 6); do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:3001/api/v1/login \
    -H "Content-Type: application/json" \
    -d '{"user":{"email":"test@fail.com","password":"wrong"}}'
done
```
**Expected:** 5 × 401, then 429 — "Rate limit exceeded"

### 13.5 Non-Friend in Expense (should fail)
See Section 7.5

### 13.6 Non-Member Creates Group Expense (should fail)
See Section 7.6

### 13.7 Non-Friend Added to Group (should fail)
See Section 6.5

---

## 14. Error Handling

### 14.1 Standard Error Format
All errors return:
```json
{
  "errors": ["Error message 1", "Error message 2"]
}
```

### 14.2 404 — Record Not Found
```
GET /api/v1/expenses/999999
Authorization: Bearer <token>
```
**Expected:** 404 — `{ "errors": ["Record not found"] }`

### 14.3 422 — Validation Error
```
POST /api/v1/expenses
Authorization: Bearer <token>
Content-Type: application/json

{
  "expense": {
    "title": "",
    "amount": "-5",
    "category_id": 5,
    "start_date": ""
  }
}
```
**Expected:** 422 — `{ "errors": ["Title can't be blank", "Amount must be greater than 0", "Start date can't be blank"] }`

### 14.4 403 — Forbidden
```
PATCH /api/v1/expenses/:id
Authorization: Bearer <non_payer_token>
Content-Type: application/json

{
  "expense": { "title": "hack" }
}
```
**Expected:** 403 — `{ "errors": ["Only the payer can perform this action"] }`

### 14.5 429 — Rate Limited
See Section 13.4

---

## Postman Tips

### Auto-Extract Token After Login

In your Login request's **Tests** tab:
```javascript
var auth = pm.response.headers.get("authorization");
if (auth) {
    pm.environment.set("token", auth.replace("Bearer ", ""));
}
```

Then use `{{token}}` in the Bearer Token field for all other requests.

### Environment Variables
```
base_url = http://localhost:3001/api/v1
token = (auto-set by login script)
user1_id = 6
user2_id = 7
```

---

## Quick Test Script

Run this to test everything at once:
```bash
bash tmp/test_security.sh
```

Or individual phase tests:
```bash
bash tmp/test_shared_expenses.sh
bash tmp/test_comments.sh
bash tmp/test_ledger.sh
bash tmp/test_notifications.sh
bash tmp/test_settlement.sh
```
