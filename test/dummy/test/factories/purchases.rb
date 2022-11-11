FactoryBot.define do
  factory :purchase do
    customer { nil }
    status { :ordered }
    total_price { 1.5 }
    delivery_zipcode { "0091234" }
    delivery_address { "MyAddress 1-2-3" }
    delivery_name { "DummyCustomer" }
    delivered_at { "2022-11-11 21:22:23" }
    remarks { "MyString" }
  end
end
