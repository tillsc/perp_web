class Start < ApplicationRecord

  self.table_name = 'startlisten'
  self.primary_keys = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :participant, foreign_key: ['Regatta_ID', 'Rennen', 'TNr']

  alias_attribute :race_number, 'Lauf'

  default_scope do
    order('Regatta_ID', 'Rennen', 'Lauf')
  end

  def to_param
    self.participant_number.to_s
  end

end
