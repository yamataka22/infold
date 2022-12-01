class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :title, null: false
      t.integer :category
      t.decimal :price, precision: 6, scale: 2
      t.integer :stock
      t.string :description
      t.datetime :published_at
      t.boolean :removed

      t.timestamps
    end
  end
end
