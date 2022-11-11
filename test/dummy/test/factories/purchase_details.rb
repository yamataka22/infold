FactoryBot.define do
  factory :purchase_detail do
    purchase { nil }
    product { nil }
    amount { 2 }
    unit_price { 1.5 }
  end
end
