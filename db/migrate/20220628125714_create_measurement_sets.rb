class CreateMeasurementSets < ActiveRecord::Migration[5.2]
  def change
    create_table :measurement_sets do |t|
      t.integer :measuring_session_id
      t.integer 'Regatta_ID', null: false
      t.integer 'Rennen', null: false
      t.string 'Lauf', limit: 2, null: false
      t.integer 'MesspunktNr'
      t.text :measurements
      t.text :measurements_history

      t.timestamps
    end
  end
end
