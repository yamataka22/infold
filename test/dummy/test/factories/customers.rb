FactoryBot.define do
  factory :customer do
    sequence(:email) { |i| "dummy#{i}@email.test" }
    sequence(:name) { |i| "DummyCustomer#{i}" }
    phone { "01-0000-1111" }
    zipcode { "0091234" }
    address { "MyAddress 1-2-3" }
    gender { :man }
    birthday { "1990-11-1" }
  end
end
