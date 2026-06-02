class AddAddressToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :address_id, :integer
    add_index :users, :address_id
  end
end
