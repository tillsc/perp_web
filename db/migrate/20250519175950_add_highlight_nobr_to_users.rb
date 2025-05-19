class AddHighlightNobrToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :highlight_nobr, :boolean
  end
end
