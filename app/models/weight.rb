class Weight < ApplicationRecord

  self.table_name = 'gewichte'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :rower, query_constraints: 'Ruderer_ID'

  alias_attribute :weight, 'Gewicht'
  alias_attribute :date, 'Datum'

  default_scope do
    order('Regatta_ID', 'Datum', 'Ruderer_ID')
  end

end
