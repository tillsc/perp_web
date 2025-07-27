class Team < ApplicationRecord

  include AliasAttributesInJson

  self.primary_key = 'Regatta_ID', 'ID'

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :team_id, 'ID'
  alias_attribute :representative_id, 'Obmann_ID'
  alias_attribute :name, 'Teamname'
  alias_attribute :country, 'Land'
  alias_attribute :city, 'Stadt'
  alias_attribute :no_entry_fee, 'Meldegeldbefreit'
  alias_attribute :entry_fee_discount, 'Meldegeldrabatt'

  COPY_FIELDS = [:name, :representative_id, :country, :city, :no_entry_fee, :entry_fee_discount]

  belongs_to :regatta, foreign_key: 'Regatta_ID'

  belongs_to :representative, class_name: 'Address', foreign_key: 'Obmann_ID', optional: true

  has_many :participants, foreign_key: ['Regatta_ID', 'Team_ID'], dependent: :restrict_with_error

  validates :name, uniqueness: { scope: ['Regatta_ID', 'Obmann_ID'] }

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta)
  }

  scope :by_filter, -> (query) do
    query.squish.split(' ').inject(self) do |scope, word|
      scope.where(arel_table[:name].matches("%#{word}%").or(arel_table[:country].matches("%#{word}%")))
    end
  end

  def self.sanitize_name(name, slashes_had_no_whitespace: false)
    slash_expr = if slashes_had_no_whitespace
                   /([^\u00A0])\u00A0?\/\u00A0?([^\u00A0])/
                 else
                   /([^\u00A0])\u00A0\/\u00A0([^\u00A0])/
                 end

    name.to_s.gsub(" ", "\u00A0").gsub(slash_expr, "\\1\u00A0\/ \\2")
  end

  def set_team_id
    unless self['ID']&.nonzero?
      self['ID'] = self.regatta.teams.maximum('ID').to_i + 1
    end
  end

end