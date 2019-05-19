class Team < ActiveRecord::Base

  self.primary_keys = 'Regatta_ID', 'ID'

  alias_attribute :name, 'Teamname'
  alias_attribute :country, 'Land'
  alias_attribute :city, 'Stadt'

end