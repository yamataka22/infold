class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_details
  enum status: { ordered: 0, charged: 1, delivered: 2 }, _prefix: true
end