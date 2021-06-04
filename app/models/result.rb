class Result < ApplicationRecord

  self.table_name = 'ergebnisse'
  self.primary_keys = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :participant, foreign_key: ['Regatta_ID', 'Rennen', 'TNr']

  has_many :times, class_name: 'ResultTime', foreign_key: ['Regatta_ID', 'Rennen', 'Lauf', 'TNr']

  alias_attribute :race_number, 'Lauf'
  alias_attribute :disqualified, 'Ausgeschieden'
  alias_attribute :comment, 'Kommentar'

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

  scope :for_rower, -> (rower) {
    joins(:participant).
      merge(Participant.for_rower(rower))
  }

  default_scope do
    order('Regatta_ID', 'Rennen', 'Lauf', 'TNr')
  end

  def to_param
    self.participant_number.to_s
  end

  def time_for(measuring_point_or_measuring_point_number)
    measuring_point_number = if measuring_point_or_measuring_point_number.is_a?(MeasuringPoint)
      measuring_point_or_measuring_point_number.number
    else
      measuring_point_or_measuring_point_number
    end
    times.find { |t| t.measuring_point_number == measuring_point_number }
  end

end
