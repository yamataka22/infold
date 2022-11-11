FactoryBot.define do
  factory :product do
    sequence(:name) { |i| "Product#{i}" }
    description { "This is a product description" }
    category { :kitchen }
    price { 1.5 }
    stock { 3 }
    published_at { "2022-11-11 21:19:03" }
    removed { false }
  end
end
