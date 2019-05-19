class Regatta < ApplicationRecord

  self.table_name = 'regatten'

  alias_attribute :name, 'DefName'

  has_many :events

  def self.current
    find(Parameter.current_regatta_id)
  end

end
