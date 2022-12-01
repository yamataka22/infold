class CreateOrderDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :order_details do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :amount
      t.decimal :unit_price, precision: 6, scale: 2

      t.timestamps
    end
  end
end
