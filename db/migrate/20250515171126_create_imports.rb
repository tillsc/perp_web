class CreateImports < ActiveRecord::Migration[8.0]
  def change
    create_table :imports do |t|
      t.integer :Regatta_ID
      t.string :source
      t.text :metadata
      t.longtext :xml
      t.longtext :results

      t.datetime :imported_at

      t.timestamps
    end

    add_column :meldungen, :imported_from, :string
    add_column :meldungen, :external_id, :string

    up_only do
      change_column :addressen, :ExterneID1, :string, limit: 200
      change_column :addressen, :eMail, :string, limit: 200

      change_column :ruderer, :VName, :string, limit: 50
    end
  end
end
