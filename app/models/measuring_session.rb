class MeasuringSession < ApplicationRecord
  belongs_to :regatta, foreign_key: 'Regatta_ID'

  # Information only! What counts is the measuring_session_id in measurement_points
  belongs_to :measuring_point, primary_key: ['Regatta_ID', 'MesspunktNr'],  foreign_key: ['Regatta_ID', 'MesspunktNr']
  alias_attribute :measuring_point_number, 'MesspunktNr'

  has_one :active_measuring_point, class_name: 'MeasuringPoint', foreign_key: 'measuring_session_id'

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

  before_validation do
    self.identifier||= SecureRandom.hex
  end

  def active?
    self.active_measuring_point&.number == self.measuring_point.number
  end

  def to_param
    self.identifier
  end

end
