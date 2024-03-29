class RegattaReferee < ApplicationRecord
  self.table_name = 'schiedsrichterliste'

  self.primary_key = 'Regatta_ID', 'Schiedsrichter_ID'

  alias_attribute :regatta_id, 'Regatta_ID'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :address, foreign_key: 'Schiedsrichter_ID'
end