class AddHideTeamNamesToMeasuringSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :measuring_sessions, :hide_team_names, :boolean
  end
end
