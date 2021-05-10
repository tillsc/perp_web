class Regatta < ApplicationRecord

  self.table_name = 'regatten'

  alias_attribute :name, 'DefName'
  alias_attribute :from_date, 'StartDatum'
  alias_attribute :to_date, 'EndDatum'

  has_many :events

  has_many :results

  has_many :teams

  has_many :measuring_points

  scope :valid, -> { where(Regatta.arel_table[:ID].gteq(1032)) }

  def self.current
    find(Parameter.current_regatta_id)
  end

end
