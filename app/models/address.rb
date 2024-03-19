class Address < ApplicationRecord

  self.table_name = 'addressen'

  alias_attribute :title, 'Titel'
  alias_attribute :first_name, 'Vorname'
  alias_attribute :last_name, 'Name'
  alias_attribute :name_suffix, 'Namenszusatz'
  alias_attribute :is_female, 'Weiblich'

  alias_attribute :external_id, 'ExterneID1'

  alias_attribute :street, 'Strasse'
  alias_attribute :zipcode, 'PLZ'
  alias_attribute :city, 'Ort'
  alias_attribute :country, 'Land'

  alias_attribute :telefone_private, "Telefon_Privat"
  alias_attribute :telefone_business, "Telefon_Geschaeftlich"
  alias_attribute :telefone_mobile, "Telefon_Mobil"
  alias_attribute :telefone_fax, "Fax"

  alias_attribute :email, 'eMail'

  alias_attribute :is_representative, 'IstObmann'
  alias_attribute :is_club, 'IstVerein'
  alias_attribute :is_referee, 'IstSchiedsrichter'
  alias_attribute :is_staff, 'IstRegattastab'

  alias_attribute :public_private_id, 'PublicPrivateID'

  has_many :teams, foreign_key: 'Obmann_ID'
  has_many :rowers, foreign_key: 'Verein_ID'

  scope :representative, -> do
    where(is_representative: true)
  end

  scope :representative_for, -> (regatta) do
    where(teams: Team.for_regatta(regatta))
  end

  scope :club, -> do
    where(is_club: true)
  end

  scope :referee, -> do
    where(is_referee: true)
  end

  scope :order_by_name, -> do
    order(:last_name, :first_name)
  end

  scope :order_existing_first, -> (regatta) do
    order(Arel.sql('EXISTS (SELECT 1 FROM teams t WHERE t.obmann_id = addressen.id AND t.regatta_id = :regatta_id) DESC', regatta_id: regatta.id)).
      order_by_name
  end

  def full_name
    "#{last_name}, #{first_name}"
  end

end