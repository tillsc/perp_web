class Participant < ApplicationRecord

  ALL_ROWER_IDX = (1..8).to_a + ["s"]
  ALL_ROWERS = ALL_ROWER_IDX.map { |i| "rower#{i}".to_sym }

  self.table_name = 'meldungen'
  self.primary_key = 'Regatta_ID', 'Rennen', 'TNr'

  belongs_to :team, query_constraints: ['Regatta_ID', 'Team_ID']

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']
  ALL_ROWER_IDX.each_with_index do |name, i|
    belongs_to ALL_ROWERS[i], class_name: 'Rower', foreign_key: "ruderer#{name}_ID"
  end

  scope :enabled, -> {
    where(withdrawn: [nil, false])
  }

  scope :for_teams, -> (teams) {
    where('Team_ID': Array.wrap(teams).map(&:id).uniq)
  }

  scope :for_rower, -> (rower) {
    where(ALL_ROWER_IDX.map { |name|
      arel_table["ruderer#{name}_ID"].eq(rower.id)
    }.inject { |sc, cond| sc.or(cond) })
  }

  default_scope do
    order('Regatta_ID', 'Rennen', 'BugNr', 'TNr')
  end

  alias_attribute :participant_id, 'TNr'
  alias_attribute :number, 'BugNr'
  alias_attribute :team_boat_number, 'TeamBoot'
  alias_attribute :withdrawn, 'Abgemeldet'
  alias_attribute :late_entry, 'Nachgemeldet'
  alias_attribute :entry_changed, 'Umgemeldet'
  alias_attribute :history, 'Historie'
  alias_attribute :disqualified, 'Ausgeschieden'

  def team_name(options = {})
    "#{self.team.try(:name)}".tap do |n|
      n << "<em>(Boot #{self.team_boat_number})</em>" if !options[:hide_team_boat_number] && self.team_boat_number
    end.html_safe
  end

  def rower_names(options = {})
    ALL_ROWERS.map { |assoc| self.send(assoc) }.each_with_index.map { |rower, i|
      if rower
        n = ERB::Util.html_escape(rower.name(options.merge(is_cox: i == 8)))
        n = options[:rower_link].call(rower, n) if options[:rower_link]
        n
      end
    }.compact.join(", ").html_safe
  end


  def all_rowers
    i = 1
    ALL_ROWERS.each_with_object({}) { |assoc, res|
      rower = self.send(assoc)
      if rower
        res[i] = rower
      end
      i+=1
    }
  end

  def active?
    !withdrawn? && !disqualified.present?
  end

  def state
    [].tap do |res|
      res << "Abgemeldet" if withdrawn?
      res << "Nachgemeldet" if late_entry?
      res << "Umgemeldet" if entry_changed?
      res << disqualified if disqualified.present?
    end.join(', ')
  end

end
