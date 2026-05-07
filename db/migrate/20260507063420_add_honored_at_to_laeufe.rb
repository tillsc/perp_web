class AddHonoredAtToLaeufe < ActiveRecord::Migration[8.1]
  def change
    up_only do
      execute "SET SESSION sql_mode = ''"
      execute "UPDATE laeufe SET ErgebnisBestaetigt = NULL WHERE ErgebnisBestaetigt = '0000-00-00 00:00:00'"
      execute "UPDATE laeufe SET ErgebnisEndgueltig = NULL WHERE ErgebnisEndgueltig = '0000-00-00 00:00:00'"
      execute "UPDATE laeufe SET SollStartZeit = NULL WHERE SollStartZeit = '0000-00-00 00:00:00'"
      execute "UPDATE laeufe SET WiegelisteFreigegeben = NULL WHERE WiegelisteFreigegeben = '0000-00-00 00:00:00'"
      execute "SET SESSION sql_mode = DEFAULT"
    end
    add_column :laeufe, :honored_at, :datetime
    up_only do
      execute "UPDATE laeufe SET honored_at = SollStartZeit WHERE SUBSTR(Lauf, 1, 1) IN ('F', 'A')"
    end
  end
end
