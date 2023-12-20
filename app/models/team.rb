class Team < ActiveRecord::Base

  self.primary_key = 'Regatta_ID', 'ID'

  alias_attribute :id, 'ID'
  alias_attribute :name, 'Teamname'
  alias_attribute :country, 'Land'
  alias_attribute :city, 'Stadt'

  belongs_to :regatta, foreign_key: 'Regatta_ID'

  has_many :participants, query_constraints: ['Regatta_ID', 'Team_ID']

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta)
  }
end