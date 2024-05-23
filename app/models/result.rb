class Result < ApplicationRecord

  self.table_name = 'ergebnisse'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']
  belongs_to :race, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :participant, query_constraints: ['Regatta_ID', 'Rennen', 'TNr']

  has_many :times, class_name: 'ResultTime', query_constraints: ['Regatta_ID', 'Rennen', 'Lauf', 'TNr'],
           inverse_of: :result, dependent: :destroy

  alias_attribute :race_number, 'Lauf'
  alias_attribute :disqualified, 'Ausgeschieden'
  alias_attribute :comment, 'Kommentar'
  alias_attribute :participant_id, 'TNr'
  alias_attribute :lane_number, 'Bahn'

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

  scope :for_rower, -> (rower) {
    joins(:participant).
      merge(Participant.for_rower(rower))
  }

  scope :for_teams, -> (teams) {
    joins(:participant).
      merge(Participant.for_teams(teams))
  }

  default_scope do
    order('Regatta_ID', 'Rennen', 'Lauf', 'TNr')
  end

  def time_for(measuring_point_or_measuring_point_number)
    mpn = MeasuringPoint.number(measuring_point_or_measuring_point_number)

    times.find { |t| t.measuring_point_number == mpn }
  end

  def set_time_for(measuring_point_or_measuring_point_number, time)
    mpn = MeasuringPoint.number(measuring_point_or_measuring_point_number)

    t = self.times.find { |t| t.measuring_point_number == mpn } ||
      self.times.build(measuring_point_number: mpn, result: self)

    t.time = ResultTime.sanitize_time(time)
    t
  end

  def destroy_time_for!(measuring_point_or_measuring_point_number)
    mpn = MeasuringPoint.number(measuring_point_or_measuring_point_number)

    self.times.find { |t| t.measuring_point_number == mpn }&.destroy!
  end

end
