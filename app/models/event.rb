class Event < ApplicationRecord

  self.table_name = 'rennen'
  self.primary_keys = 'Regatta_ID', 'Rennen'

  alias_attribute :number, 'Rennen'
  alias_attribute :name_short, 'NameK'
  alias_attribute :name_de, 'NameD'
  alias_attribute :name_en, 'NameE'

  belongs_to :regatta, foreign_key: 'Regatta_ID'

  default_scope do
    order('Regatta_ID', 'Rennen')
  end

  def name
    self.name_de
  end

end
