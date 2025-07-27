class Start < ApplicationRecord

  self.table_name = 'startlisten'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr'

  include HasRaceNumber

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :participant, foreign_key: ['Regatta_ID', 'Rennen', 'TNr']

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :race_number, 'Lauf'
  alias_attribute :participant_id, 'TNr'
  alias_attribute :lane_number, 'Bahn'

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }
  scope :for_teams, -> (teams) {
    joins(:participant).
      merge(Participant.for_teams(teams))
  }

  scope :for_rower, -> (rower) {
    joins(:participant).
      merge(Participant.for_rower(rower))
  }

  scope :for_participants, -> (participants) {
    where(participant_id: participants.map(&:participant_id))
  }

  scope :upcoming, -> {
    joins(race: :event).
      merge(Race.upcoming)
  }

  default_scope do
    order(arel_table[:regatta_id].asc, arel_table[:event_number].asc, arel_table[:race_number].asc)
  end

end
