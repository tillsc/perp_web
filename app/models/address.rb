class Address < ApplicationRecord

  self.table_name = 'addressen'

  alias_attribute :is_representative, 'IstObmann'
  alias_attribute :public_private_id, 'PublicPrivateID'

  alias_attribute :first_name, 'Vorname'
  alias_attribute :last_name, 'Name'
  alias_attribute :email, 'eMail'

  has_many :teams, foreign_key: 'obmann_id'

  scope :representative, -> do
    where(is_representative: true)
  end

  scope :representative_for, -> (regatta) do
    where(teams: Team.for_regatta(regatta))
  end

  scope :order_by_name, -> do
    order(:last_name, :first_name)
  end

  def full_name
    "#{last_name}, #{first_name}"
  end

end