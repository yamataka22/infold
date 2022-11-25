class Purchase < ApplicationRecord
  belongs_to :customer
  has_many :purchase_details
  enum status: { purchased: 0, charged: 1, delivered: 2, canceled: 3 }, _prefix: true
end
