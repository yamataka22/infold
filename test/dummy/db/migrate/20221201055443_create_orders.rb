class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.integer :status
      t.decimal :total_price, precision: 6, scale: 2
      t.string :delivery_zipcode
      t.string :delivery_address
      t.string :delivery_name
      t.datetime :delivered_at
      t.string :remarks

      t.timestamps
    end
  end
end
