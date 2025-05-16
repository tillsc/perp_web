class Import < ApplicationRecord
  belongs_to :regatta, foreign_key: 'Regatta_ID'

  serialize :metadata, coder: JSON
  serialize :results, coder: JSON

  scope :drv, -> {
    where(source: "").create_with(source: "")
  }

end
