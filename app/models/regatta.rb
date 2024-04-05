class Regatta < ApplicationRecord

  self.table_name = 'regatten'

  alias_attribute :name, 'DefName'
  alias_attribute :year, 'Jahr'
  alias_attribute :from_date, 'StartDatum'
  alias_attribute :to_date, 'EndDatum'
  alias_attribute :currency, 'Waehrung'

  alias_attribute :organizer_id, 'Veranstalter_ID'

  belongs_to :organizer, foreign_key: 'Veranstalter_ID'

  has_many :events, foreign_key: 'Regatta_ID', inverse_of: :regatta

  has_many :races, foreign_key: 'Regatta_ID', inverse_of: :regatta

  has_many :results, foreign_key: 'Regatta_ID', inverse_of: :regatta

  has_many :participants, foreign_key: 'Regatta_ID', inverse_of: :regatta

  has_many :teams, foreign_key: 'Regatta_ID', inverse_of: :regatta

  has_many :measuring_points, foreign_key: 'Regatta_ID', inverse_of: :regatta

  has_many :regatta_referees, foreign_key: 'Regatta_ID', inverse_of: :regatta
  has_many :referees, through: :regatta_referees, source: :address

  scope :valid, -> { where(Regatta.arel_table[:ID].gteq(1032)) }

  validates :name, presence: true, length: { minimum: 4 }, uniqueness: true
  validates :from_date, presence: true

  def self.current
    find(Parameter.current_regatta_id)
  end

  def active?
    Parameter.current_regatta_id.to_i == self.id
  end

end
