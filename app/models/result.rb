class Result < ApplicationRecord

  self.table_name = 'ergebnisse'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr'

  include HasRaceNumber

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :participant, foreign_key: ['Regatta_ID', 'Rennen', 'TNr']

  has_many :times, class_name: 'ResultTime', foreign_key: ['Regatta_ID', 'Rennen', 'Lauf', 'TNr'],
           inverse_of: :result, dependent: :destroy,
           autosave: true

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :event_number, 'Rennen'
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
    order(arel_table[:regatta_id].asc, arel_table[:event_number].asc, arel_table[:race_number].asc, arel_table[:participant_id].asc)
  end

  def time_for(measuring_point_or_measuring_point_number)
    mpn = MeasuringPoint.number(measuring_point_or_measuring_point_number)

    times.find { |t| t.measuring_point_number == mpn }
  end

  def sort_time_for(measuring_point_or_measuring_point_number)
    self.time_for(measuring_point_or_measuring_point_number)&.sort_time_str ||
      "ZZZZZZZZZ#{self.lane_number || self.participant_id}"
  end

  def set_time_for(measuring_point_or_measuring_point_number, time)
    mpn = MeasuringPoint.number(measuring_point_or_measuring_point_number)

    t = self.times.find { |t| t.measuring_point_number == mpn } ||
      self.times.build(measuring_point_number: mpn, result: self)

    t.time = ResultTime.sanitize_time(time)
    t
  end

  def times_hash
    measuring_points = MeasuringPoint.where(regatta_id: self.regatta_id).for_event(self.event)
    measuring_points.inject({}) do |hash, point|
      hash.merge(MeasuringPoint.number(point) => time_for(point)&.time)
    end
  end

  def times_hash=(h)
    h.each do |mp, time|
      set_time_for(mp, time)
    end
  end

  def destroy_time_for!(measuring_point_or_measuring_point_number)
    mpn = MeasuringPoint.number(measuring_point_or_measuring_point_number)

    self.times.find { |t| t.measuring_point_number == mpn }&.destroy!
  end

end
