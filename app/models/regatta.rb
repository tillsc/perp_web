class Regatta < ApplicationRecord

  self.table_name = 'regatten'

  alias_attribute :name, 'DefName'

  has_many :events

  has_many :results

  def self.current
    find(Parameter.current_regatta_id)
  end

end
