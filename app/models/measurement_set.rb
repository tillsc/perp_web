class MeasurementSet < ApplicationRecord

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :measuring_point, primary_key: ['Regatta_ID', 'MesspunktNr'],  foreign_key: ['Regatta_ID', 'MesspunktNr']
  belongs_to :measuring_session, optional: true

  serialize :measurements, JSON
  serialize :measurements_history, JSON

  alias_attribute :race_number, 'Lauf'

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

end
