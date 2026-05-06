class AddRangToErgebnisse < ActiveRecord::Migration[8.1]
  def change
    add_column :ergebnisse, :rank, :integer, unsigned: true
  end
end
