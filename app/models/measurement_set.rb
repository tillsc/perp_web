class MeasurementSet < ApplicationRecord

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :measuring_point, primary_key: ['Regatta_ID', 'MesspunktNr'],  foreign_key: ['Regatta_ID', 'MesspunktNr']
  belongs_to :measuring_session

  serialize :measurements, JSON
  serialize :measurements_history, JSON

  alias_attribute :race_number, 'Lauf'

  def self.find_or_initialize_for(measuring_session, race)
    raise "Inactive MeasuringSession! (#{measuring_session.identifier})" unless measuring_session.active_measuring_point
    self.
      create_with(measuring_point: measuring_session.active_measuring_point).
      find_or_initialize_by(race: race, regatta: measuring_session.regatta, measuring_session: measuring_session)
  end

end
