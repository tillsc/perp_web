class AddSomeIndexesToRowersAndParticipants < ActiveRecord::Migration[7.1]
  def change
    add_index :ruderer, :Verein_ID
    add_index :ruderer, :ExterneID1
    add_index :ruderer, :VName
    add_index :ruderer, :JahrG

    add_index :meldungen, :ruderer1_ID
    add_index :meldungen, :ruderer2_ID
    add_index :meldungen, :ruderer3_ID
    add_index :meldungen, :ruderer4_ID
    add_index :meldungen, :ruderer5_ID
    add_index :meldungen, :ruderer6_ID
    add_index :meldungen, :ruderer7_ID
    add_index :meldungen, :ruderer8_ID
    add_index :meldungen, :ruderers_ID
    add_index :meldungen, :BugNr
  end
end
