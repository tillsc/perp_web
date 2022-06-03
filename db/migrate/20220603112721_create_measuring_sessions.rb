class CreateMeasuringSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :measuring_sessions do |t|
      t.string :device_description
      t.integer 'Regatta_ID'
      t.integer 'MesspunktNr' # Informational
      t.string :identifier

      t.timestamps
    end

    add_column 'messpunkte', :measuring_session_id, :integer
  end
end
