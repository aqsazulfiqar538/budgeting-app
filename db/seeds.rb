# frozen_string_literal: true

# ============================================================================
# SEEDS — Budgeting App
# ============================================================================
#
# Run:   bin/rails db:seed
# Reset: bin/rails db:reset   (drops + creates + migrates + seeds)
#
# Safe to run multiple times (idempotent via find_or_create_by)
# Demo data only runs in development environment
#
# Default credentials (all passwords: password123):
#   arslan@test.com   — main test user (5 friends, 4 groups)
#   ahmad@test.com    — friend + group member
#   sara@test.com     — friend + group member
#   zain@test.com     — friend + group member
#   ayesha@test.com   — friend (has pending request from zain)

# ============================================================================
# 1. CATEGORIES (runs in all environments)
# ============================================================================

puts "=== Categories ==="

categories = {
  "Food" => { subs: [
    { name: "Groceries" },
    { name: "Dining Out" },
    { name: "Snacks" }
  ] },
  "Travel" => { subs: [
    { name: "Fuel" },
    { name: "Taxi"},
    { name: "Parking" }
  ] },
  "Medication" => { subs: [
    { name: "Pharmacy" },
    { name: "Doctor Visit"}
  ] },
  "Miscellaneous" => { subs: [
    { name: "Shopping" },
    { name: "Entertainment" },
    { name: "Bills" }
  ] }
}

categories.each do |name, attrs|
  parent = Category.find_or_create_by!(name: name, user_id: nil, parent_id: nil)

  attrs[:subs].each do |sub|
    Category.find_or_create_by!(name: sub[:name], parent_id: parent.id, user_id: nil) do |c|
      c.name = sub[:name]
    end
  end
end

Category.find_or_create_by!(name: "Settlement", user_id: nil, parent_id: nil) do |c|
  c.name = "Settlement"
end

# ============================================================================
# 2. DEMO DATA (development only)
# ============================================================================

unless Rails.env.development?
  puts "\nSkipping demo data (not development environment)"
  puts "Done!"
  return
end

puts "\n=== Demo Data ==="

# --- Helper methods ---

def find_or_create_user(attrs)
  user = User.find_or_create_by!(email: attrs[:email]) do |u|
    u.password = "password123"
    u.first_name = attrs[:first_name]
    u.last_name = attrs[:last_name]
    u.phone_number = attrs[:phone_number]
    u.date_of_birth = attrs[:date_of_birth]
  end
  user.confirm unless user.confirmed?
  user
end

def make_friends(a, b, status: :accepted)
  ids = [a.id, b.id].sort
  Friendship.find_or_create_by!(user_id: ids[0], friend_id: ids[1]) do |f|
    f.requested_by_id = a.id
    f.status = status
  end
end

def make_group(name:, creator:, members:, group_type: :other)
  group = Group.find_or_create_by!(name: name, created_by_id: creator.id) do |g|
    g.group_type = group_type
  end
  ([creator] + members).each { |u| group.group_memberships.find_or_create_by!(user_id: u.id) }
  group
end

def add_expense(payer:, title:, amount:, category:, start_date:, group: nil, participants: nil, notes: nil)
  expense = payer.expenses.find_or_create_by!(title: title) do |e|
    e.category = category
    e.amount = amount
    e.start_date = start_date
    e.group = group
    e.notes = notes
  end

  return expense if expense.expense_participants.any? || participants.nil?

  share = (amount / participants.size.to_d).round(2)

  participants.each do |user|
    paid = user.id == payer.id ? amount : 0
    expense.expense_participants.create!(user: user, paid_share: paid, owed_share: share)
  end

  participants.reject { |u| u.id == payer.id }.each do |ower|
    expense.repayments.create!(from_user: ower, to_user: payer, amount: share)
  end

  label = participants.size > 1 ? "shared" : "individual"
  expense.comments.find_or_create_by!(comment_type: :system_comment, user: payer) do |c|
    c.content = "#{payer.full_name} created #{label} expense '#{title}' — Rs. #{amount}"
  end

  expense
end

# --- Users ---
puts "\n  Users:"

arslan = find_or_create_user(email: "arslan@test.com", first_name: "Arslan", last_name: "Ahmad", phone_number: "+923001234567", date_of_birth: "1995-01-15")
ahmad  = find_or_create_user(email: "ahmad@test.com", first_name: "Ahmad", last_name: "Khan", phone_number: "+923009876543", date_of_birth: "1996-05-20")
sara   = find_or_create_user(email: "sara@test.com", first_name: "Sara", last_name: "Ali", phone_number: "+923008888888", date_of_birth: "1997-03-10")
zain   = find_or_create_user(email: "zain@test.com", first_name: "Zain", last_name: "Malik", phone_number: "+923007777777", date_of_birth: "1994-11-25")
ayesha = find_or_create_user(email: "ayesha@test.com", first_name: "Ayesha", last_name: "Syed", phone_number: "+923006666666", date_of_birth: "1998-07-08")

[arslan, ahmad, sara, zain, ayesha].each { |u| puts "    #{u.full_name} (#{u.email}) — #{u.initials}" }

# --- Friendships ---
puts "\n  Friendships:"

[
  [arslan, ahmad], [arslan, sara], [arslan, zain], [arslan, ayesha],
  [ahmad, sara], [ahmad, zain], [sara, ayesha]
].each { |a, b| make_friends(a, b); puts "    #{a.first_name} <-> #{b.first_name} (accepted)" }

make_friends(zain, ayesha, status: :pending)
puts "    Zain -> Ayesha (pending)"

# --- Custom categories ---
puts "\n  Custom Categories:"

Category.find_or_create_by!( user_id: arslan.id) do |c|
  c.name = "Office Lunch"
end
puts "    Arslan: Office Lunch"

Category.find_or_create_by!(user_id: ahmad.id) do |c|
  c.name = "Gym & Fitness"
end
puts "    Ahmad: Gym & Fitness"

# --- Groups ---
puts "\n  Groups:"

office = make_group(name: "Office Dinner", creator: arslan, members: [ahmad, sara])
trip   = make_group(name: "Islamabad Trip", creator: arslan, members: [ahmad, zain], group_type: :trip)
flat   = make_group(name: "Flat Expenses", creator: ahmad, members: [arslan, zain], group_type: :apartment)
girls  = make_group(name: "Girls Hangout", creator: sara, members: [ayesha])

[office, trip, flat, girls].each { |g| puts "    #{g.name} (#{g.group_type}) — #{g.members.count} members" }

# --- Subcategory lookups ---
groceries     = Category.find_by!(name: "groceries")
dining        = Category.find_by!(name: "Dining Out")
fuel          = Category.find_by!(name: "Fuel")
taxi          = Category.find_by!(name: "Taxi")
pharmacy      = Category.find_by!(name: "Pharmacy")
doctor        = Category.find_by!(name: "Doctor Visit")
shopping      = Category.find_by!(name: "Shopping")
entertainment = Category.find_by!(name: "Entertainment")
bills         = Category.find_by!(name: "Bills")
snacks        = Category.find_by!(name: "Snacks")

# --- Individual expenses ---
puts "\n  Individual Expenses:"

[
  { payer: arslan, title: "Weekly Groceries",     amount: 3500, category: groceries,     start_date: 7.days.ago },
  { payer: arslan, title: "Panadol & Vitamins",   amount: 850,  category: pharmacy,      start_date: 5.days.ago },
  { payer: arslan, title: "Netflix Subscription",  amount: 1500, category: entertainment, start_date: 3.days.ago },
  { payer: arslan, title: "Electricity Bill",      amount: 4200, category: bills,         start_date: 2.days.ago },
  { payer: arslan, title: "New Shoes",             amount: 6500, category: shopping,      start_date: 1.day.ago },
  { payer: ahmad,  title: "Protein Shake",         amount: 2800, category: Category.find_by!(name: "Gym & Fitness"), start_date: 4.days.ago },
  { payer: ahmad,  title: "Uber to Office",        amount: 450,  category: taxi,          start_date: 3.days.ago },
  { payer: ahmad,  title: "Internet Bill",         amount: 3000, category: bills,         start_date: 1.day.ago },
  { payer: sara,   title: "Sara's Groceries",      amount: 2200, category: groceries,     start_date: 6.days.ago },
  { payer: sara,   title: "Petrol Fill-up",        amount: 5000, category: fuel,          start_date: 2.days.ago },
  { payer: zain,   title: "Amazon Shopping",        amount: 8500, category: shopping,      start_date: 4.days.ago },
  { payer: ayesha, title: "Doctor Checkup",         amount: 3000, category: doctor,        start_date: 3.days.ago }
].each do |data|
  add_expense(**data)
  puts "    #{data[:payer].first_name}: #{data[:title]} — Rs. #{data[:amount]}"
end

# --- Shared expenses ---
puts "\n  Shared Expenses:"

shared_data = [
  { payer: arslan, title: "Team Lunch at Howdy",    amount: 4500,  category: dining, participants: [arslan, ahmad, sara], group: office, start_date: 5.days.ago },
  { payer: ahmad,  title: "Friday Pizza Night",     amount: 3600,  category: dining, participants: [arslan, ahmad, sara], group: office, start_date: 3.days.ago },
  { payer: arslan, title: "Fuel to Islamabad",      amount: 6000,  category: fuel,   participants: [arslan, ahmad, zain], group: trip,   start_date: 7.days.ago },
  { payer: zain,   title: "Hotel Booking",           amount: 15000, category: Category.find_by!(name: "Miscellaneous"), participants: [arslan, ahmad, zain], group: trip, start_date: 6.days.ago },
  { payer: ahmad,  title: "Monal Restaurant",        amount: 9000,  category: dining, participants: [arslan, ahmad, zain], group: trip,   start_date: 6.days.ago },
  { payer: ahmad,  title: "Flat Electricity Bill",   amount: 8000,  category: bills,  participants: [arslan, ahmad, zain], group: flat,   start_date: 4.days.ago },
  { payer: arslan, title: "Flat Internet Bill",      amount: 4500,  category: bills,  participants: [arslan, ahmad, zain], group: flat,   start_date: 2.days.ago },
  { payer: sara,   title: "Coffee & Snacks",         amount: 1200,  category: snacks, participants: [sara, ayesha],        start_date: 1.day.ago },
  { payer: arslan, title: "Gift for Boss",           amount: 5000,  category: shopping, participants: [arslan, ahmad],      start_date: Date.current },
  { payer: sara,   title: "Brunch at Cafe Aylanto",  amount: 4000,  category: dining, participants: [sara, ayesha],        group: girls,  start_date: 2.days.ago }
]

shared_data.each do |data|
  e = add_expense(**data)
  share = (data[:amount] / data[:participants].size.to_d).round(2)
  puts "    #{data[:payer].first_name} paid '#{data[:title]}' — Rs. #{data[:amount]} (#{data[:participants].size}-way, Rs. #{share} each)"
end

# --- Comments ---
puts "\n  Comments:"

threads = {
  "Team Lunch at Howdy" => [
    { user: ahmad, content: "Great lunch! The biryani was amazing" },
    { user: sara,  content: "Loved it! Can we go again next week?" },
    { user: arslan, content: "Sure! Let's plan for Thursday" }
  ],
  "Hotel Booking" => [
    { user: arslan, content: "Hotel was really nice, good pick Zain!" },
    { user: ahmad,  content: "The view was incredible" },
    { user: zain,   content: "Thanks! Can everyone settle up this week?" },
    { user: arslan, content: "I'll send mine tomorrow" }
  ],
  "Flat Electricity Bill" => [
    { user: arslan, content: "Bill seems high this month, did we leave AC on?" },
    { user: zain,   content: "Probably. Let's be more careful next month" },
    { user: ahmad,  content: "Agreed. I'll collect everyone's share by Friday" }
  ],
  "Coffee & Snacks" => [
    { user: ayesha, content: "That cappuccino was so good" },
    { user: sara,   content: "Right?! We should go there more often" }
  ]
}

threads.each do |title, comments|
  expense = Expense.find_by(title: title)
  next unless expense
  comments.each do |data|
    expense.comments.find_or_create_by!(content: data[:content], user: data[:user]) do |c|
      c.comment_type = :user_comment
    end
  end
  puts "    #{title}: #{comments.size} comments"
end

# --- Settlements ---
puts "\n  Settlements:"

settlement_cat = Category.find_by!(name: "Settlement")

# Ahmad settles office lunch with Arslan
r1 = Expense.find_by(title: "Team Lunch at Howdy")&.repayments&.where(settled: false)&.find_by(from_user: ahmad, to_user: arslan)
if r1 && !r1.settled?
  r1.update!(settled: true, settled_at: Time.current)
  Expense.find_or_create_by!(title: "Settlement: #{ahmad.full_name} -> #{arslan.full_name}", user: ahmad, category: settlement_cat) do |e|
    e.amount = r1.amount; e.start_date = Date.current; e.group = office
  end
  r1.expense.comments.find_or_create_by!(content: "#{ahmad.full_name} settled Rs. #{r1.amount}", comment_type: :system_comment) do |c|
    c.user = ahmad
  end
  puts "    Ahmad settled Rs. #{r1.amount} with Arslan (Office Lunch)"
end

# Arslan settles hotel with Zain
r2 = Expense.find_by(title: "Hotel Booking")&.repayments&.where(settled: false)&.find_by(from_user: arslan, to_user: zain)
if r2 && !r2.settled?
  r2.update!(settled: true, settled_at: Time.current)
  Expense.find_or_create_by!(title: "Settlement: #{arslan.full_name} -> #{zain.full_name}", user: arslan, category: settlement_cat) do |e|
    e.amount = r2.amount; e.start_date = Date.current; e.group = trip
  end
  r2.expense.comments.find_or_create_by!(content: "#{arslan.full_name} settled Rs. #{r2.amount}", comment_type: :system_comment) do |c|
    c.user = arslan
  end
  puts "    Arslan settled Rs. #{r2.amount} with Zain (Hotel)"
end

# --- Notifications ---
puts "\n  Notifications:"

def notify(recipient:, actor:, type:, content:, source: nil)
  Notification.find_or_create_by!(user: recipient, content: content) do |n|
    n.created_by = actor
    n.notification_type = type
    n.source = source
  end
end

shared_data.each do |data|
  expense = Expense.find_by(title: data[:title])
  next unless expense
  data[:participants].reject { |u| u.id == data[:payer].id }.each do |p|
    notify(recipient: p, actor: data[:payer], type: :expense_added, content: "#{data[:payer].full_name} added '#{data[:title]}' — Rs. #{data[:amount]}", source: expense)
  end
end

notify(recipient: ayesha, actor: zain, type: :friend_added, content: "#{zain.full_name} sent you a friend request")

if r1
  notify(recipient: arslan, actor: ahmad, type: :debt_settled, content: "#{ahmad.full_name} settled Rs. #{r1.amount} for 'Team Lunch at Howdy'")
end
if r2
  notify(recipient: zain, actor: arslan, type: :debt_settled, content: "#{arslan.full_name} settled Rs. #{r2.amount} for 'Hotel Booking'")
end

threads.each do |title, comments|
  expense = Expense.find_by(title: title)
  next unless expense
  comments.each do |data|
    expense.participants.where.not(id: data[:user].id).each do |p|
      notify(recipient: p, actor: data[:user], type: :comment_added, content: "#{data[:user].full_name} commented on '#{title}'", source: expense)
    end
  end
end

puts "    #{Notification.count} notifications created"

# ============================================================================
# SUMMARY
# ============================================================================

puts "\n#{'=' * 60}"
puts "SEED COMPLETE"
puts "#{'=' * 60}"
puts ""
puts "Users:          #{User.count}"
puts "Friendships:    #{Friendship.count} (#{Friendship.accepted.count} accepted, #{Friendship.pending.count} pending)"
puts "Expenses:       #{Expense.active.count} (#{Expense.active.individual.count} individual, #{Expense.active.shared_expenses.count} shared)"
puts "Participants:   #{ExpenseParticipant.count}"
puts "Comments:       #{Comment.count} (#{Comment.system_comment.count} system, #{Comment.user_comment.count} user)"
puts "Notifications:  #{Notification.count} (#{Notification.unread.count} unread)"
puts ""
puts "Login: all passwords are 'password123'"
puts "  arslan@test.com  — main user, 4 friends, member of 3 groups"
puts "  ahmad@test.com   — friend of arslan/sara/zain, member of 3 groups"
puts "  sara@test.com    — friend of arslan/ahmad/ayesha, member of 2 groups"
puts "  zain@test.com    — friend of arslan/ahmad, member of 2 groups, pending request to ayesha"
puts "  ayesha@test.com  — friend of arslan/sara, member of 1 group, has pending request from zain"
