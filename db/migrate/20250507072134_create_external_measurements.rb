class CreateExternalMeasurements < ActiveRecord::Migration[8.0]
  def change
    create_table :external_measurements do |t|
      t.integer :MesspunktNr
      t.datetime :time

      # t.timestamps
    end
  end
end
