class MeasuringSession < ApplicationRecord
  belongs_to :regatta, foreign_key: 'Regatta_ID'

  # Information only! What counts is the measuring_session_id in measurement_points
  belongs_to :measuring_point, foreign_key: ['Regatta_ID', 'MesspunktNr']

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :measuring_point_number, 'MesspunktNr'

  has_one :active_measuring_point, class_name: 'MeasuringPoint', foreign_key: 'measuring_session_id'

  has_many :measurement_sets, inverse_of: :measuring_session, dependent: :nullify

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

  scope :with_stats, -> {
    select("#{self.table_name}.*").
      select("(SELECT COUNT(*) FROM #{MeasurementSet.table_name} mset WHERE mset.measuring_session_id = #{self.table_name}.id) AS measurement_set_count").
      select("(SELECT MAX(mset.updated_at) FROM #{MeasurementSet.table_name} mset WHERE mset.measuring_session_id = #{self.table_name}.id) AS last_measurement_set_at").
      order(created_at: :desc)
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
