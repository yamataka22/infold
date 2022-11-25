class Product < ApplicationRecord
  has_many :purchase_details
  has_one_attached :image
  enum category: { sofa: 1, bed: 2, accessory: 3, kitchen: 4 }
end
