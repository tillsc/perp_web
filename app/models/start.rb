class Start < ApplicationRecord

  self.table_name = 'startlisten'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']
  belongs_to :race, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf']

  belongs_to :participant, query_constraints: ['Regatta_ID', 'Rennen', 'TNr']

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

  scope :by_type_short, -> (type_short) do
    ts = Array(type_short).dup
    scope = arel_table['Lauf'].matches("#{ts.pop}%")
    while ts.any?
      scope = scope.or(arel_table['Lauf'].matches("#{ts.pop}%"))
    end
    where(scope)
  end

  default_scope do
    order('Regatta_ID', 'Rennen', 'Lauf')
  end

  def race_type_short
    self.race_number.to_s[0]
  end

end
