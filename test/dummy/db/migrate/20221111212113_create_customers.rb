class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :email
      t.string :name
      t.string :phone
      t.string :zipcode
      t.string :address
      t.integer :gender
      t.date :birthday

      t.timestamps
    end
  end
end
