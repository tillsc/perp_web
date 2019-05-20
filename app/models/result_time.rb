class ResultTime < ApplicationRecord

  self.table_name = 'zeiten'
  self.primary_keys = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr', 'MesspunktNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']
  belongs_to :result, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf', 'TNr']

  belongs_to :measuring_point, foreign_key: ['Regatta_ID', 'MesspunktNr']

  belongs_to :participant, foreign_key: ['Regatta_ID', 'Rennen', 'TNr']

  alias_attribute :race_number, 'Lauf'
  alias_attribute :measuring_point_number, 'MesspunktNr'
  alias_attribute :time, 'Zeit'

  default_scope do
    order('Regatta_ID', 'Rennen', 'Lauf', 'MesspunktNr', 'Zeit')
  end

end
