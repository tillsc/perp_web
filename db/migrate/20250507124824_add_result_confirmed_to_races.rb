class AddResultConfirmedToRaces < ActiveRecord::Migration[8.0]
  def change
    add_column :laeufe, "ErgebnisBestaetigt", :datetime, precision: nil
  end
end
