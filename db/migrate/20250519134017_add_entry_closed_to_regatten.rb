class AddEntryClosedToRegatten < ActiveRecord::Migration[8.0]
  def change
    add_column :regatten, :entry_closed, :boolean

    up_only do
      execute "UPDATE regatten SET entry_closed = true WHERE YEAR(startdatum) < #{Date.current.year}"
    end
  end
end
