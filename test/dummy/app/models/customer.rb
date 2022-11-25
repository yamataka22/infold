class Customer < ApplicationRecord
  has_many :purchases

  enum gender: { male: 1, female: 2, other: 0 }
end
