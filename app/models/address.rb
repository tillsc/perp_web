class Address < ApplicationRecord

    self.table_name = 'addressen'

    alias_attribute :is_representative, 'IstObmann'
    alias_attribute :public_private_id, 'PublicPrivateID'

    alias_attribute :first_name, 'Vorname'
    alias_attribute :last_name, 'Name'


    has_many :teams, foreign_key: 'obmann_id'
    
    scope :representative, -> do
      where(is_representative: true)
    end  

end   