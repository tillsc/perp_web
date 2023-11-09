class Organizer < ApplicationRecord

  self.table_name = 'veranstalter'

  alias_attribute :name, 'Name'

end
