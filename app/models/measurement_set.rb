class MeasurementSet < ApplicationRecord

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']
  belongs_to :race, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :measuring_point, query_constraints: ['Regatta_ID', 'MesspunktNr']
  alias_attribute :measuring_point_number, 'MesspunktNr'

  belongs_to :measuring_session, optional: true

  belongs_to :referee_starter, class_name: 'Address', optional: true
  belongs_to :referee_aligner, class_name: 'Address', optional: true
  belongs_to :referee_umpire, class_name: 'Address', optional: true
  belongs_to :referee_finish_judge, class_name: 'Address', optional: true

  serialize :measurements, coder: JSON
  serialize :measurements_history, coder: JSON

  alias_attribute :race_number, 'Lauf'

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

  def locked_for?(measuring_session)
    self.measuring_session_id.nil? || self.measuring_session_id != measuring_session.id
  end

  def correct?
    return true unless self.measurements.is_a?(Array)

    rel_time_required = self.race.event.measuring_point_type(self.measuring_point_number) != :start
    self.measurements.all? { |m| m[0].to_i > 0 && m[1].present? && (!rel_time_required || m[2].present?) }
  end

end
