class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :description
      t.integer :category
      t.float :price
      t.integer :stock
      t.datetime :published_at
      t.boolean :removed

      t.timestamps
    end
  end
end
