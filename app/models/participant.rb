class Participant < ApplicationRecord

  ALL_ROWER_IDX = (1..8).to_a + ["s"]
  ALL_ROWERS = ALL_ROWER_IDX.map { |i| "rower#{i}".to_sym }

  self.table_name = 'meldungen'
  self.primary_keys = 'Regatta_ID', 'Rennen', 'TNr'

  belongs_to :team, foreign_key: ['Regatta_ID', 'Team_ID']

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  ALL_ROWER_IDX.each_with_index do |name, i|
    belongs_to ALL_ROWERS[i], class_name: 'Rower', foreign_key: "ruderer#{name}_ID"
  end

  default_scope do
    order('Regatta_ID', 'Rennen', 'BugNr', 'TNr')
  end

  alias_attribute :number, 'BugNr'
  alias_attribute :team_boat_number, 'TeamBoot'
  alias_attribute :withdrawn, 'Abgemeldet'
  alias_attribute :late_entry, 'Nachgemeldet'
  alias_attribute :entry_changed, 'Umgemeldet'
  alias_attribute :history, 'Historie'

  def to_param
    self.tnr.to_s
  end

  def team_name
    "#{self.team.try(:name)}".tap do |n|
      n << "<em>(Boot #{self.team_boat_number})</em>" if self.team_boat_number
    end.html_safe
  end

  def rower_names(options = {})
    ALL_ROWERS.map { |assoc| self.send(assoc) }.each_with_index.map { |rower, i|
      rower && rower.name(options.merge(is_cox: i == 8))
    }.compact.join(", ")
  end

  def state
    [].tap do |res|
      res << "Abgemeldet" if withdrawn?
      res << "Nachgemeldet" if late_entry?
      res << "Umgemeldet" if entry_changed?
    end.join(', ')
  end

end
