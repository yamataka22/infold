class CreatePurchaseDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :purchase_details do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :amount
      t.float :unit_price

      t.timestamps
    end
  end
end
