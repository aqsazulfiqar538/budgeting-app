# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

[
  { name: "Food",          slug: "food",          sort_order: 1 },
  { name: "Travel",        slug: "travel",        sort_order: 2 },
  { name: "Medication",    slug: "medication",     sort_order: 3 },
  { name: "Miscellaneous", slug: "miscellaneous", sort_order: 4 }
].each do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name       = attrs[:name]
    c.sort_order = attrs[:sort_order]
  end
end

puts "Seeded #{Category.count} categories."
