class AddReloadDisabledToMeasuringSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :measuring_sessions, :autoreload_disabled, :boolean
  end
end
