class Participant < ApplicationRecord

  ALL_ROWER_IDX = (1..8).to_a + ["s"]
  ALL_ROWERS = ALL_ROWER_IDX.map { |i| "rower#{i}".to_sym }
  ALL_ROWERS_WITH_WEIGHTS = ALL_ROWERS.inject({}) { |h, rel_name| h.merge(rel_name => :weights) }

  self.table_name = 'meldungen'
  self.primary_key = 'Regatta_ID', 'Rennen', 'TNr'

  belongs_to :team, query_constraints: ['Regatta_ID', 'Team_ID']

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']
  ALL_ROWER_IDX.each_with_index do |name, i|
    belongs_to ALL_ROWERS[i], class_name: 'Rower', foreign_key: "ruderer#{name}_ID", optional: i > 0
  end

  has_many :starts, query_constraints: ['Regatta_ID', 'Rennen', 'TNr']

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

  scope :with_weight_info, -> (date) {
    scope = joins(:event, starts: :race).
      merge(Race.planned_for(date))
    Weight.apply_info_scope(scope, date).
      select("#{self.table_name}.*").
      group("#{Participant.table_name}.Rennen, #{Participant.table_name}.TNr")
  }

  default_scope do
    order('Regatta_ID', 'Rennen', 'BugNr', 'TNr')
  end

  alias_attribute :participant_id, 'TNr'
  alias_attribute :number, 'BugNr'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :team_id, 'Team_ID'
  alias_attribute :team_boat_number, 'TeamBoot'
  alias_attribute :withdrawn, 'Abgemeldet'
  alias_attribute :late_entry, 'Nachgemeldet'
  alias_attribute :entry_changed, 'Umgemeldet'
  alias_attribute :history, 'Historie'
  alias_attribute :disqualified, 'Ausgeschieden'
  ALL_ROWER_IDX.each_with_index do |idx|
    alias_attribute "rower#{idx}_id", "ruderer#{idx}_ID"
  end

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


  def all_rowers(no_cox: false)
    i = 1
    ALL_ROWERS.each_with_object({}) { |assoc, res|
      next if no_cox && assoc == :rowers

      rower = self.send(assoc)
      if rower
        res[i] = rower
      end
      i+=1
    }
  end

  def rower_fields
    not_used = ((self.event.rower_count + 1)..8).map { |i| "rower#{i}".to_sym }
    not_used += [:rowers] unless self.event.has_cox?
    ALL_ROWERS - not_used
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

  def set_participant_id
    unless self['TNr']&.nonzero?
      self['TNr'] = self.event.participants.maximum('TNr').to_i + 1
    end
  end

end
