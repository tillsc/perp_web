class Participant < ApplicationRecord

  ALL_ROWER_IDX = (1..8).to_a + ["s"]
  ALL_ROWER_FIELD_NAMES = ALL_ROWER_IDX.map { |i| "ruderer#{i}_ID" }
  ALL_ROWERS = ALL_ROWER_IDX.map { |i| "rower#{i}".to_sym }
  ALL_ROWERS_WITH_WEIGHTS = ALL_ROWERS.inject({}) { |h, rel_name| h.merge(rel_name => :weights) }
  ALL_ROWERS_WITH_CLUBS = ALL_ROWERS.inject({}) { |h, rel_name| h.merge(rel_name => :club) }

  self.table_name = 'meldungen'
  self.primary_key = 'Regatta_ID', 'Rennen', 'TNr'

  belongs_to :team, foreign_key: ['Regatta_ID', 'Team_ID']

  has_many :race_team_participants, class_name: 'Participant',
           foreign_key: ['Regatta_ID', 'Team_ID', 'Rennen'],
           primary_key: ['Regatta_ID', 'Team_ID', 'Rennen']

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  ALL_ROWER_IDX.each_with_index do |name, i|
    belongs_to ALL_ROWERS[i], class_name: 'Rower', foreign_key: ALL_ROWER_FIELD_NAMES[i], optional: i > 0
  end

  has_many :starts, foreign_key: ['Regatta_ID', 'Rennen', 'TNr'],
           inverse_of: :participant, dependent: :destroy
  has_many :results, foreign_key: ['Regatta_ID', 'Rennen', 'TNr'],
           inverse_of: :participant, dependent: :restrict_with_error

  scope :enabled, -> {
    where(withdrawn: [nil, false])
  }

  scope :withdrawn, -> {
    where.not(withdrawn: [nil, false])
  }

  scope :active, -> {
    where(disqualified: [nil, '']).where(withdrawn: [nil, false])
  }

  scope :for_regatta, -> (regatta) do
    where(regatta_id: regatta.id)
  end

  scope :for_teams, -> (teams) {
    where('Team_ID': Array.wrap(teams).map(&:team_id).uniq)
  }

  def self.any_rower_eq_condition(equals_rower, no_cox: false)
    fields = ALL_ROWER_FIELD_NAMES
    fields -= ["ruderers_ID"] if no_cox
    fields.map { |field_name|
      arel_table[field_name].eq(equals_rower)
    }.inject(&:or)
  end

  scope :for_rower, -> (rower) {
    where(any_rower_eq_condition(rower.id))
  }

  scope :for_club, -> (club_address) {
    where(
      'EXISTS (:rower)',
      rower: Rower.for_club(club_address).
        where(ALL_ROWER_IDX.map { |name| arel_table["ruderer#{name}_ID"].eq(Rower.arel_table[:id]) }.inject(&:or))
    )
  }

  scope :with_weight_info, -> (date) {
    scope = joins(:event, starts: :race).
      merge(Race.planned_for(date))
    Weight.apply_info_scope(scope, date).
      select("#{self.table_name}.*").
      group(Weight.info_scope_group_by_columns(base_table: Participant) + [Participant.arel_table[:participant_id]])
  }

  default_scope do
    order(arel_table[:regatta_id].asc,  arel_table[:event_number].asc, arel_table[:number].asc, arel_table[:participant_id].asc)
  end

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :participant_id, 'TNr'
  alias_attribute :number, 'BugNr'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :team_id, 'Team_ID'
  alias_attribute :team_boat_number, 'TeamBoot'
  alias_attribute :entry_fee, 'Meldegeld'
  alias_attribute :withdrawn, 'Abgemeldet'
  alias_attribute :late_entry, 'Nachgemeldet'
  alias_attribute :entry_changed, 'Umgemeldet'
  alias_attribute :history, 'Historie'
  alias_attribute :disqualified, 'Ausgeschieden'
  ALL_ROWER_IDX.each_with_index do |idx|
    alias_attribute "rower#{idx}_id", "ruderer#{idx}_ID"
  end

  def team_name(hide_team_boat_number: false, hide_age_category: false, regatta: nil)
    "<strong>#{self.team&.name}</strong>".tap do |n|
      # "\u2005" – like &thinsp;, but breakable
      n << "\u2005<em>(Boot&nbsp;#{self.team_boat_number})</em>" if !hide_team_boat_number && self.team_boat_number
      if !hide_age_category
        ac = self.age_category(regatta: regatta)
        n << "&thinsp;(#{ac})" if ac
      end
    end.html_safe
  end

  def problem_with_team_boat_number?(all_participants)
    other_race_team_participants = all_participants.select do |p|
      p.regatta_id == self.regatta_id && p.event_number == self.event_number &&
        p.team&.name == self.team&.name &&
        p.participant_id != self.participant_id
    end
    if other_race_team_participants.length > 0
      if self.team_boat_number.to_i <= 0
        true
      else
        other_race_team_participants.any? do |p|
          p.team_boat_number.to_i == self.team_boat_number.to_i
        end
      end
    else
      self.team_boat_number.present?
    end
  end

  def label(regatta: nil)
    "#{self.number} - #{self.team_name(regatta: regatta)}".html_safe
  end

  def rower_names(options = {})
    ALL_ROWERS.map { |assoc| self.send(assoc) }.each_with_index.map { |rower, i|
      if rower
        rower_options = options.
          slice(:no_year_of_birth, :no_nobr, :first_name_last_name).
          merge(is_cox: i == 8)
        n = ERB::Util.html_escape(rower.name(**rower_options))
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

  def rower_years_of_birth(including_cox: false)
    (ALL_ROWERS - (including_cox ? [] : [:rowers])).
      map { |assoc| self.send(assoc)&.year_of_birth.presence&.to_i }.
      compact
  end

  def rower_fields
    not_used = ((self.event.rower_count + 1)..8).map { |i| "rower#{i}".to_sym }
    not_used += [:rowers] unless self.event.has_cox?
    ALL_ROWERS - not_used
  end

  def rower_at(position)
    raise "invalid position" unless position.downcase.to_s =~ /^[1-8s]$/
    self.send("rower#{position}")
  end

  def set_rower_at(position, rower)
    raise "invalid position" unless position.downcase.to_s =~ /^[1-8s]$/
    self.send("rower#{position}=", rower)
  end

  def active?
    !withdrawn? && !disqualified.present?
  end

  def disqualified?
    disqualified.present?
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
      self.strict_loading!(false)
      self['TNr'] = self.event.participants.maximum('TNr').to_i + 1
    end
  end

  before_update :write_history
  def write_history
    if self.entry_changed
      changes = []

      if self.changed.include?("Team_ID")
        old_team = self.regatta.teams.find_by(id: self.changed_attributes["Team_ID"])
        changes << "#{old_team.name} &rArr; #{self.team&.name || '-'}" if old_team
      end

      ALL_ROWER_IDX.each do |idx|
        field = "ruderer#{idx}_ID"
        if self.changed.include?(field)
          old_rower = Rower.find_by(id: self.changed_attributes[field])
          changes << "#{old_rower.name} &rArr; #{self.send("rower#{idx}")&.name || '-'}" if old_rower
        end
      end

      if self.changed.include?("BugNr")
        changes << "BugNr #{self.changed_attributes["BugNr"]} &rArr; #{self.number}"
      end

      if changes.any?
        prepend_history_entry('Ummeldung', changes.join(' - '))
      end
    end

    if self.changed.include?("Abgemeldet")
      prepend_history_entry(self.withdrawn? ? "Abmeldung" : "Anmeldung")
    end
  end

  def prepend_history_entry(what_happened, details = nil)
    new_entry = "#{DateTime.now.strftime("%d.%m.%Y %T")}: <b>#{what_happened}</b>"
    new_entry += " - #{details}" if details.present?
    self.history = "#{new_entry}<br>\n#{self.history}"
  end

  def age_category(regatta: nil, including_cox: false)
    (regatta || self.regatta).age_category(self.rower_years_of_birth(including_cox: including_cox))
  end

end
