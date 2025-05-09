class Team < ApplicationRecord

  include AliasAttributesInJson

  self.primary_key = 'Regatta_ID', 'ID'

  alias_attribute :team_id, 'ID'
  alias_attribute :representative_id, 'Obmann_ID'
  alias_attribute :name, 'Teamname'
  alias_attribute :country, 'Land'
  alias_attribute :city, 'Stadt'
  alias_attribute :no_entry_fee, 'Meldegeldbefreit'
  alias_attribute :entry_fee_discount, 'Meldegeldrabatt'

  COPY_FIELDS = [:name, :representative_id, :country, :city, :no_entry_fee, :entry_fee_discount]

  belongs_to :regatta, foreign_key: 'Regatta_ID'

  belongs_to :representative, class_name: 'Address', foreign_key: 'Obmann_ID'

  has_many :participants, foreign_key: ['Regatta_ID', 'Team_ID'], dependent: :restrict_with_error

  validates :name, uniqueness: { scope: 'Regatta_ID' }

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta)
  }

  scope :by_filter, -> (query) {
    where(arel_table[:name].matches("%#{query}%"))
  }

  def set_team_id
    unless self['ID']&.nonzero?
      self['ID'] = self.regatta.teams.maximum('ID').to_i + 1
    end
  end

end