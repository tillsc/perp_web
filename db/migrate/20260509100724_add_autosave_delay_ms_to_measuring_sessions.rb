class AddAutosaveDelayMsToMeasuringSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :measuring_sessions, :autosave_delay_ms, :integer, null: false, default: 1000
  end
end
