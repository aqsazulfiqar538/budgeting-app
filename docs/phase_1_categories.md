# Phase 1: Categories Enhancement (Subcategories + Custom Categories)

## What Was Added

### Migration
- `db/migrate/20260417100002_enhance_categories.rb` — adds `user_id` (nullable FK for custom categories), `parent_id` (nullable self-ref FK for subcategories), `icon` (string). Replaces slug unique index with 3 partial unique indexes (system top-level, system subcategories, user custom).

### Model Changes
- `app/models/category.rb` — added `belongs_to :user` (optional), `belongs_to :parent` (optional self-referential), `has_many :subcategories`. New scopes: `top_level`, `system_categories`, `for_user(user)`. Auto-generates slug from name.
- `app/models/user.rb` — added `has_many :custom_categories`

### New Controller
- `app/controllers/api/v1/categories_controller.rb` — `index` (public, returns tree with subcategories) and `create` (authenticated, creates custom category for current user)

### Updated Serializer
- `app/serializers/category_serializer.rb` — added `slug`, `icon`, `active`, `sort_order`, `parent_id`, `custom` (boolean), and `has_many :subcategories` relationship

### Seeds
- `db/seeds.rb` — updated to seed subcategories with icons:
  - Food → Groceries, Dining Out, Snacks
  - Travel → Fuel, Taxi, Parking
  - Medication → Pharmacy, Doctor Visit
  - Miscellaneous → Shopping, Entertainment, Bills

### Route
- Added `resources :categories, only: [:index, :create]` under api/v1

## API Endpoints

### List Categories (public — no auth required)
```
GET /api/v1/categories
```
Returns all system categories (with nested subcategories) + user's custom categories (if authenticated).

### Create Custom Category (auth required)
```
POST /api/v1/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "category": {
    "name": "Office Lunch",
    "icon": "briefcase",
    "parent_id": null
  }
}
```
Creates a custom category scoped to the current user. Optionally nest under an existing category with `parent_id`.

## How to Test

**1. List categories (no auth)**
```bash
curl http://localhost:3001/api/v1/categories | python3 -m json.tool
# Returns: 4 parent categories with 11 subcategories
```

**2. Login to get token**
```bash
curl -s -D - -X POST http://localhost:3001/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"arslan@test.com","password":"password123"}}' \
  | grep authorization
# Copy the Bearer token from the authorization header
```

**3. Create custom category**
```bash
curl -X POST http://localhost:3001/api/v1/categories \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":{"name":"Office Lunch","icon":"briefcase"}}'
# Response: 201 — custom category with "custom": true
```

**4. Create custom subcategory under Food (id=1)**
```bash
curl -X POST http://localhost:3001/api/v1/categories \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":{"name":"Street Food","icon":"food-stand","parent_id":1}}'
# Response: 201 — subcategory with parent_id: 1
```

**5. List again with auth (includes custom)**
```bash
curl http://localhost:3001/api/v1/categories \
  -H "Authorization: Bearer YOUR_TOKEN"
# Shows system categories + "Office Lunch" (custom) + Food now has 4 subcategories
```

## Test Results

| # | Test | Expected | Actual |
|---|------|----------|--------|
| 1 | List categories (no auth) | 200 — 4 parents + 11 subcategories | 200 |
| 2 | Create custom category | 201 — custom: true | 201 |
| 3 | Create custom subcategory | 201 — parent_id set | 201 |
| 4 | List with auth | Shows system + custom | 200 |
| 5 | Existing expenses still work | No breakage | Confirmed |

## Category Response Structure

```json
{
  "data": [
    {
      "id": "1",
      "type": "category",
      "attributes": {
        "name": "Food",
        "slug": "food",
        "icon": "utensils",
        "active": true,
        "sort_order": 1,
        "parent_id": null,
        "custom": false
      },
      "relationships": {
        "subcategories": {
          "data": [
            { "id": "5", "type": "category" },
            { "id": "6", "type": "category" }
          ]
        }
      }
    }
  ],
  "included": [
    {
      "id": "5",
      "type": "category",
      "attributes": {
        "name": "Groceries",
        "slug": "groceries",
        "icon": "shopping-cart",
        "parent_id": 1,
        "custom": false
      }
    }
  ]
}
```

## Notes
- System categories have `user_id: null`, custom have `user_id: current_user.id`
- Slug is auto-generated from name if not provided
- Custom categories are only visible to the user who created them
- `parent_id` is optional — omit for top-level, provide to nest under a parent
- The `custom` attribute in the response is a derived boolean (true if user_id is present)
