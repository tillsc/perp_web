class DropRegattasSecondaryUniqueKey < ActiveRecord::Migration[8.1]
  def change
    remove_index "regatten", ["Jahr","Kurzbezeichnung"], name: "SECONDARY", unique: true
    add_index "regatten", ["Jahr"]
  end
end
