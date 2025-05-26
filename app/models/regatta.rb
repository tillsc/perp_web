class Regatta < ApplicationRecord

  self.table_name = 'regatten'

  AGE_CATEGORIES = [:drv, :fisa_masters]

  alias_attribute :name, 'DefName'
  alias_attribute :year, 'Jahr'
  alias_attribute :from_date, 'StartDatum'
  alias_attribute :to_date, 'EndDatum'
  alias_attribute :currency, 'Waehrung'

  alias_attribute :organizer_id, 'Veranstalter_ID'

  belongs_to :organizer, foreign_key: 'Veranstalter_ID'

  has_many :events, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :races, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :results, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :starts, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :participants, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :teams, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :measuring_points, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :destroy

  has_many :measuring_sessions, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :restrict_with_error

  has_many :regatta_referees, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :destroy
  has_many :referees, through: :regatta_referees, source: :address

  has_many :imports, foreign_key: 'Regatta_ID',
           inverse_of: :regatta, dependent: :destroy

  scope :valid, -> { where(Regatta.arel_table[:ID].gteq(1032)) }

  validates :name, presence: true, length: { minimum: 4 }, uniqueness: true
  validates :from_date, presence: true

  def number_of_lanes
    8
  end

  def lane_1_on_finish_camera_side?
    true
  end

  # Show extra lane especially for finish cam to be able to deal with one more boat
  def show_extra_lane?
    true
  end

  def self.current
    find(Parameter.current_regatta_id)
  end

  def active?
    Parameter.current_regatta_id.to_i == self.id
  end

  def calculate_ages_for(years_of_birth)
    Array.wrap(years_of_birth).
      map { |birth_year| self.year - birth_year }
  end

  def age_category(years_of_birth)
    case self.show_age_categories&.to_s
    when "drv"
      self.drv_age_category(years_of_birth)
    when "fisa_masters"
      self.fisa_masters_age_category(years_of_birth)
    end
  end

  def drv_age_category(years_of_birth)
    max_age = calculate_ages_for(years_of_birth).max
    case max_age
    when 0..12
      'Kind 12'
    when 13..14
      'Kind 13/14'
    when 15..16
      'Junior B'
    when 17..18
      'Junior A'
    when 19..22
      'B'
    when 23..Float::INFINITY
      'A'
    end
  end

  def fisa_masters_age_category(years_of_birth)
    ages = calculate_ages_for(years_of_birth)
    average_age = ages.sum.to_f / ages.size

    case average_age
    when 85..Float::INFINITY
      'K'
    when 80...85
      'J'
    when 75...80
      'I'
    when 70...75
      'H'
    when 65...70
      'G'
    when 60...65
      'F'
    when 55...60
      'E'
    when 50...55
      'D'
    when 43...50
      'C'
    when 36...43
      'B'
    when 27...36
      'A'
    else
      'Too young for Masters'
    end
  end

end
