class AddAddressToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :address_id, :integer
    add_index :users, :address_id
    add_foreign_key :users, :addressen, column: :address_id, primary_key: "ID"
  end
end
